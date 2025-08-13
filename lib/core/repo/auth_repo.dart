import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msbridge/core/models/user_model.dart';

class AuthResult {
  final User? user;
  final String? error;

  AuthResult({this.user, this.error});

  bool get isSuccess => user != null;
}

class AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AuthResult> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = _auth.currentUser;
      return AuthResult(user: user);
    } catch (e) {
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
        return AuthResult(error: "User registration failed.");
      }

      await user.updateDisplayName(fullName);

      await user.sendEmailVerification();
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
      return AuthResult(error: "Registration failed: $e");
    }
  }

  Future<String?> logout() async {
    try {
      await _auth.signOut();
      _authStateController.add(null);
      return null;
    } catch (e) {
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

      await user.sendEmailVerification();
      return AuthResult(error: "Verification email sent successfully!");
    } catch (e) {
      return AuthResult(error: "Failed to send verification email: $e");
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
      return AuthResult(error: "Failed to get current user email: $e");
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
      return AuthResult(user: null, error: "Error getting user ID: $e");
    }
  }
}
