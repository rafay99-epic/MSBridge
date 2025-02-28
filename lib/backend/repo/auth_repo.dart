import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:msbridge/backend/models/user_model.dart';

class AuthResult {
  final models.User? user;
  final String? error;

  AuthResult({this.user, this.error});

  bool get isSuccess => user != null;
}

class AuthRepo {
  final Account _account;

  AuthRepo(Client client) : _account = Account(client);

  /// 🔹 Login User
  Future<AuthResult> login(String email, String password) async {
    try {
      await _account.createEmailPasswordSession(
          email: email, password: password);
      final user = await _account.get();
      return AuthResult(user: user);
    } catch (e) {
      return AuthResult(error: "Login failed: $e");
    }
  }

  /// 🔹 Register User
  // Future<AuthResult> register(
  //     String email, String password, String name) async {
  //   try {
  //     await _account.create(
  //         userId: ID.unique(), email: email, password: password, name: name);
  //     return await login(email, password); // Auto-login after registration
  //   } catch (e) {
  //     return AuthResult(error: "Registration failed: $e");
  //   }
  // }

  /// 🔹 Register User
  Future<AuthResult> register(String email, String password, String fullName,
      String phoneNumber) async {
    try {
      // Step 1: Create the user in Appwrite Authentication
      final user = await _account.create(
          userId: ID.unique(),
          email: email,
          password: password,
          name: fullName);

      // Step 2: Create a UserModel instance
      final userModel = UserModel(
        id: user.$id,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );

      // Step 3: Store user data in the Appwrite Database
      final client = _account.client;
      final databases = Databases(client);

      await databases.createDocument(
        databaseId: '67c0b2f300378eaaa782',
        collectionId: '67c0bb3c0014db7a367d',
        documentId: userModel.id,
        data: userModel.toMap(),
        permissions: [
          "read(user:${userModel.id})",
          "update(user:${userModel.id})",
          "delete(user:${userModel.id})",
        ],
      );

      // Step 4: Auto-login the user after registration
      return await login(email, password);
    } catch (e) {
      return AuthResult(error: "Registration failed: $e");
    }
  }

  /// 🔹 Logout User
  Future<String?> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      _authStateController.add(null);
      return null; // No error
    } catch (e) {
      return "Logout failed: $e"; // Return error message
    }
  }

  /// 🔹 Get Current User (if logged in)
  Future<AuthResult> getCurrentUser() async {
    try {
      final user = await _account.get();
      return AuthResult(user: user);
    } catch (e) {
      return AuthResult(error: "No user session found.");
    }
  }

  final StreamController<models.User?> _authStateController =
      StreamController.broadcast();

  Stream<models.User?> authStateChanges() {
    _checkAuthState();
    return _authStateController.stream;
  }

  Future<void> _checkAuthState() async {
    try {
      final user = await _account.get();
      _authStateController.add(user);
    } catch (e) {
      _authStateController.add(null);
    }
  }

  /// 🔹 Reset Password (sends email with reset link)
  Future<String?> resetPassword(String email) async {
    try {
      await _account.createRecovery(
          email: email, url: "https://yourapp.com/reset-password");
      return null; // No error
    } catch (e) {
      return "Password reset failed: $e";
    }
  }
}
