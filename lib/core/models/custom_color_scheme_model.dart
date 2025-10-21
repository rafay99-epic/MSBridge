// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';

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

  static DateTime? _parseFirestoreDate(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }

    if (dateValue is Object && dateValue.toString().contains('Timestamp')) {
      try {
        return (dateValue as dynamic).toDate();
      } catch (e, stackTrace) {
        FlutterBugfender.sendCrash(
            'Error parsing date: $e', stackTrace.toString());
        return DateTime.now();
      }
    }

    if (dateValue is Map<String, dynamic>) {
      final seconds = dateValue['seconds'] ?? dateValue['_seconds'];
      final nanoseconds = dateValue['nanoseconds'] ?? dateValue['_nanoseconds'];

      if (seconds != null) {
        final int milliseconds =
            (seconds * 1000 + (nanoseconds ?? 0) / 1000000).round();
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }
    }

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  factory CustomColorSchemeModel.fromMap(Map<String, dynamic> map) {
    return CustomColorSchemeModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Custom Theme',
      primary: Color(map['primary'] ?? 0xFF000000),
      secondary: Color(map['secondary'] ?? 0xFF000000),
      background: Color(map['background'] ?? 0xFFFFFFFF),
      textColor: Color(map['textColor'] ?? 0xFF000000),
      createdAt: _parseFirestoreDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseFirestoreDate(map['updatedAt']) ?? DateTime.now(),
      isSynced: map['isSynced'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      lastSyncedAt: _parseFirestoreDate(map['lastSyncedAt']),
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
    if (isDeleted) return true; // Always sync deletions
    return !isSynced; // Sync non-deleted items only if not already synced
  }

  /// Generate a unique ID
  static String generateId() {
    final now = DateTime.now();
    return 'custom_color_${now.millisecondsSinceEpoch}_${(now.microsecond % 1000).toString().padLeft(3, '0')}';
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
        other.textColor == textColor &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isSynced == isSynced &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        primary.hashCode ^
        secondary.hashCode ^
        background.hashCode ^
        textColor.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isSynced.hashCode ^
        isDeleted.hashCode;
  }
}
