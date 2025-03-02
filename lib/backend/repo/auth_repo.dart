import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msbridge/backend/models/user_model.dart';

class AuthResult {
  final User? user;
  final String? error;

  AuthResult({this.user, this.error});

  bool get isSuccess => user != null;
}

class AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Login User
  Future<AuthResult> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = _auth.currentUser;
      return AuthResult(user: user);
    } catch (e) {
      return AuthResult(error: "Login failed: $e");
    }
  }

  /// 🔹 Register User
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

      final userModel = UserModel(
        id: user.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return AuthResult(user: user);
    } catch (e) {
      return AuthResult(error: "Registration failed: $e");
    }
  }

  /// 🔹 Logout User
  Future<String?> logout() async {
    try {
      await _auth.signOut();
      _authStateController.add(null);
      return null;
    } catch (e) {
      return "Logout failed: $e";
    }
  }

  /// 🔹 Get Current User (if logged in)
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

  /// 🔹 Reset Password (sends email with reset link)
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return "Password reset failed: $e";
    }
  }

  /// 🔹 Check if User's Email is Verified
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

  /// 🔹 Check if user's email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;

    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }

    return false;
  }

  /// 🔹 Resend Email Verification
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
}
