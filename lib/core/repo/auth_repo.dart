import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:msbridge/core/models/user_model.dart';
import 'package:msbridge/core/utils/rate_limiter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:msbridge/core/services/background/scheduler_registration.dart';

class AuthResult {
  final User? user;
  final String? error;

  AuthResult({this.user, this.error});

  bool get isSuccess => user != null;
}

class AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RateLimiter _rateLimiter = RateLimiter();

  Future<AuthResult> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = _auth.currentUser;
      // Re-register background periodic sync after successful sign-in
      try {
        await SchedulerRegistration.registerAdaptive();
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'Failed to register background periodic sync: $e',
        );
      }
      return AuthResult(user: user);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Login failed: $e',
      );
      return AuthResult(error: "Login failed: $e");
    }
  }

  Future<AuthResult> register(String email, String password, String fullName,
      String phoneNumber) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        FirebaseCrashlytics.instance.recordError(
          Exception('User registration failed.'),
          StackTrace.current,
          reason: 'User registration failed.',
        );
        return AuthResult(error: "User registration failed.");
      }

      await user.updateDisplayName(fullName);

      // Send email verification (temporarily using default settings)
      try {
        await user.sendEmailVerification();
      } catch (verificationError) {
        FirebaseCrashlytics.instance.recordError(
          verificationError,
          StackTrace.current,
          reason:
              'Email verification failed during registration: $verificationError',
        );
      }

      const String defaultRole = 'user';

      final userModel = UserModel(
        id: user.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        role: defaultRole,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return AuthResult(user: user);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Registration failed: $e',
      );

      // Provide more specific error messages
      String errorMessage = "Registration failed";

      if (e.toString().contains('email-already-in-use')) {
        errorMessage =
            "An account with this email already exists. Please try logging in instead.";
      } else if (e.toString().contains('weak-password')) {
        errorMessage = "Password is too weak. Please use a stronger password.";
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = "Please enter a valid email address.";
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage =
            "Too many registration attempts. Please wait 24 hours before trying again.";
      } else if (e.toString().contains('network')) {
        errorMessage =
            "Network error. Please check your connection and try again.";
      } else {
        errorMessage = "Registration failed: $e";
      }

      return AuthResult(error: errorMessage);
    }
  }

  Future<String?> logout() async {
    try {
      try {
        await Workmanager().cancelByUniqueName('msbridge.periodic.all.id');
        await Workmanager().cancelByUniqueName('msbridge.oneoff.sync.id');
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'Failed to cancel background sync jobs: $e',
        );
      }
      await _auth.signOut();
      _authStateController.add(null);
      return null;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Logout failed: $e',
      );
      return "Logout failed: $e";
    }
  }

  Future<AuthResult> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return AuthResult(user: user);
      }
      return AuthResult(error: "No user session found.");
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get current user: $e',
      );
      return AuthResult(error: "No user session found.");
    }
  }

  final StreamController<User?> _authStateController =
      StreamController.broadcast();

  Stream<User?> authStateChanges() {
    _checkAuthState();
    return _auth.authStateChanges();
  }

  Future<void> _checkAuthState() async {
    final user = _auth.currentUser;
    _authStateController.add(user);
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(user: _auth.currentUser);
    } catch (e) {
      return AuthResult(error: "Password reset failed: \$e");
    }
  }

  Future<AuthResult> checkEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return AuthResult(error: "No user logged in.");
      }
      await user.reload();
      user = _auth.currentUser;

      if (user!.emailVerified) {
        return AuthResult(user: user);
      } else {
        return AuthResult(
            error: "Email not verified. Please check your inbox.");
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Email verification check failed: $e',
      );
      return AuthResult(error: "Email verification check failed: $e");
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;

    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }

    return false;
  }

  Future<AuthResult> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return AuthResult(error: "No user is currently logged in.");
      }

      if (user.emailVerified) {
        return AuthResult(error: "Your email is already verified.");
      }

      // Check rate limiting
      final rateLimitKey = 'verification_email_${user.uid}';
      if (!_rateLimiter.canMakeRequest(rateLimitKey)) {
        final remainingCooldown = _rateLimiter.getRemainingCooldown(
            rateLimitKey, const Duration(minutes: 1));
        if (remainingCooldown != null && remainingCooldown > Duration.zero) {
          final minutes = remainingCooldown.inMinutes;
          final seconds = remainingCooldown.inSeconds % 60;
          return AuthResult(
              error:
                  "Please wait ${minutes}m ${seconds}s before requesting another email.");
        }

        final remainingRequests =
            _rateLimiter.getRemainingRequests(rateLimitKey, 5);
        if (remainingRequests <= 0) {
          return AuthResult(
              error:
                  "Maximum attempts reached. Please wait 24 hours before trying again.");
        }
      }

      // Send email verification (temporarily using default settings)
      try {
        await user.sendEmailVerification();

        // Only record successful requests
        _rateLimiter.recordRequest(rateLimitKey);

        return AuthResult(user: user);
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'Failed to send verification email: $e',
        );
        // If Firebase blocks the request, don't record it as a successful attempt
        if (e.toString().contains('too-many-requests')) {
          return AuthResult(
              error:
                  "Firebase has blocked this device. Please wait 24 hours or try from a different network.");
        }

        // For other errors, still record the attempt
        _rateLimiter.recordRequest(rateLimitKey);
        rethrow; // Re-throw to be caught by outer catch block
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to send verification email: $e',
      );

      // Provide more user-friendly error messages
      String errorMessage = "Failed to send verification email";

      if (e.toString().contains('too-many-requests')) {
        errorMessage =
            "Too many requests. Please wait 24 hours before trying again.";
        // Reset rate limiter for this user when Firebase blocks them
        final user = _auth.currentUser;
        if (user != null) {
          _rateLimiter.reset('verification_email_${user.uid}');
        }
      } else if (e.toString().contains('network')) {
        errorMessage =
            "Network error. Please check your connection and try again.";
      } else if (e.toString().contains('user-not-found')) {
        errorMessage = "User account not found. Please log in again.";
      } else {
        errorMessage =
            "Failed to send verification email. Please try again later.";
      }

      return AuthResult(error: errorMessage);
    }
  }

  Future<AuthResult> getCurrentUserEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return AuthResult(user: user);
      } else {
        return AuthResult(error: "No user logged in.");
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get current user email: $e',
      );
      return AuthResult(error: "Failed to get current user email: $e");
    }
  }

  Future<Map<String, String>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return {
          'id': user.uid,
          'email': user.email ?? '',
          'fullName': user.displayName ?? '',
          'phoneNumber': user.phoneNumber ?? '',
        };
      }
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': user.uid,
        'email': user.email ?? '',
        'fullName': (data['fullName'] as String?) ?? (user.displayName ?? ''),
        'phoneNumber':
            (data['phoneNumber'] as String?) ?? (user.phoneNumber ?? ''),
      };
    } catch (e) {
      return null;
    }
  }

  Future<String?> updateUserProfile(
      {required String fullName, required String phoneNumber}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';
      // Update auth profile display name
      await user.updateDisplayName(fullName);
      // Update Firestore profile document
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': user.email,
        'id': user.uid,
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }

  Future<AuthResult> deleteUserAndData() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return AuthResult(error: "No user logged in.");
      }

      // Delete all user documents under users/{uid}/notes
      final notesCollection =
          _firestore.collection('users').doc(user.uid).collection('notes');
      final notesSnapshot = await notesCollection.get();
      if (notesSnapshot.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        for (final doc in notesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Delete the user profile document
      await _firestore.collection('users').doc(user.uid).delete();

      // Finally delete the auth user (may require recent login)
      await user.delete();

      return AuthResult(user: null); // success indicated by error == null
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to delete user and data: $e',
      );
      return AuthResult(error: "Failed to delete user and data: $e");
    }
  }

  Future<AuthResult> getUserRole() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return AuthResult(user: null, error: 'No user logged in.');
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'user';
        return AuthResult(user: user, error: role);
      } else {
        return AuthResult(user: user, error: 'User document not found.');
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get user role: $e',
      );
      return AuthResult(user: null, error: "Error getting user role: $e");
    }
  }

  Future<AuthResult> getUserId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult(user: null, error: 'No user logged in.');
      }
      return AuthResult(user: user, error: user.uid);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get user ID: $e',
      );
      return AuthResult(user: null, error: "Error getting user ID: $e");
    }
  }
}
