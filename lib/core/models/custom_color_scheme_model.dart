// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

class CustomColorSchemeModel {
  final String id;
  final String userId;
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color textColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final bool isDeleted;
  final DateTime? lastSyncedAt;
  final String? deviceId;

  CustomColorSchemeModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.textColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
    this.lastSyncedAt,
    this.deviceId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a copy with updated values
  CustomColorSchemeModel copyWith({
    String? id,
    String? userId,
    String? name,
    Color? primary,
    Color? secondary,
    Color? background,
    Color? textColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastSyncedAt,
    String? deviceId,
  }) {
    return CustomColorSchemeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      textColor: textColor ?? this.textColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  /// Convert to Map for Firebase/Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'primary': primary.toARGB32(),
      'secondary': secondary.toARGB32(),
      'background': background.toARGB32(),
      'textColor': textColor.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'deviceId': deviceId,
    };
  }

  /// Create from Map (Firebase/Firestore)
  factory CustomColorSchemeModel.fromMap(Map<String, dynamic> map) {
    return CustomColorSchemeModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Custom Theme',
      primary: Color(map['primary'] ?? 0xFF000000),
      secondary: Color(map['secondary'] ?? 0xFF000000),
      background: Color(map['background'] ?? 0xFFFFFFFF),
      textColor: Color(map['textColor'] ?? 0xFF000000),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      isSynced: map['isSynced'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      lastSyncedAt: map['lastSyncedAt'] != null
          ? DateTime.parse(map['lastSyncedAt'])
          : null,
      deviceId: map['deviceId'],
    );
  }

  /// Convert to JSON string for SharedPreferences
  String toJson() => json.encode(toMap());

  /// Create from JSON string
  factory CustomColorSchemeModel.fromJson(String source) =>
      CustomColorSchemeModel.fromMap(json.decode(source));

  /// Mark as deleted with proper tracking
  CustomColorSchemeModel markAsDeleted(String deviceId) {
    return copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
      deviceId: deviceId,
      isSynced: false,
    );
  }

  /// Mark as restored
  CustomColorSchemeModel restore() {
    return copyWith(
      isDeleted: false,
      updatedAt: DateTime.now(),
      deviceId: null,
      isSynced: false,
    );
  }

  /// Check if should be synced
  bool get shouldSync {
    if (!isDeleted) return !isSynced;
    return !isSynced; // Always sync deletions
  }

  /// Generate a unique ID
  static String generateId() {
    return 'custom_color_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }

  /// Create default custom color scheme
  static CustomColorSchemeModel createDefault(String userId) {
    return CustomColorSchemeModel(
      id: generateId(),
      userId: userId,
      name: 'My Custom Theme',
      primary: const Color(0xFF2196F3),
      secondary: const Color(0xFFFF9800),
      background: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF000000),
    );
  }

  @override
  String toString() {
    return 'CustomColorSchemeModel(id: $id, name: $name, primary: $primary, secondary: $secondary, background: $background, textColor: $textColor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomColorSchemeModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.background == background &&
        other.textColor == textColor;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        primary.hashCode ^
        secondary.hashCode ^
        background.hashCode ^
        textColor.hashCode;
  }
}
