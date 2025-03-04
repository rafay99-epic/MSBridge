import 'dart:convert';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.role,
  });

  // Convert to JSON for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role,
    };
  }

  // Convert JSON response from Appwrite to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['\$id'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? '',
    );
  }

  // Convert to JSON string (if needed)
  String toJson() => json.encode(toMap());

  // Convert JSON string to UserModel (if needed)
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}
