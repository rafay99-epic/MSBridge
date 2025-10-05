// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:msbridge/core/models/custom_color_scheme_model.dart';

class CustomColorSchemeRepo {
  static const String _prefsKey = 'custom_color_schemes';
  static const String _activeSchemeKey = 'active_custom_color_scheme';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Memory cache for better performance
  List<CustomColorSchemeModel>? cachedSchemes;
  CustomColorSchemeModel? cachedActiveScheme;
  DateTime? lastCacheUpdate;
  static const Duration cacheExpiry = Duration(minutes: 5);

  // Singleton instance for better memory management
  static CustomColorSchemeRepo? _instance;
  static CustomColorSchemeRepo get instance {
    _instance ??= CustomColorSchemeRepo._internal();
    return _instance!;
  }

  CustomColorSchemeRepo._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  Future<String?> _getCurrentUserId() async {
    final user = _auth.currentUser;
    return user?.uid;
  }

  /// Save custom color scheme locally
  Future<bool> saveLocalScheme(CustomColorSchemeModel scheme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schemesJson = prefs.getStringList(_prefsKey) ?? [];

      // Remove existing scheme with same ID
      schemesJson.removeWhere((json) {
        try {
          final existingScheme = CustomColorSchemeModel.fromJson(json);
          return existingScheme.id == scheme.id;
        } catch (e) {
          return false;
        }
      });

      // Add updated scheme
      schemesJson.add(scheme.toJson());

      await prefs.setStringList(_prefsKey, schemesJson);
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to save custom color scheme locally');
      return false;
    }
  }

  /// Load all custom color schemes from local storage
  Future<List<CustomColorSchemeModel>> loadLocalSchemes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schemesJson = prefs.getStringList(_prefsKey) ?? [];

      return schemesJson
          .map((json) {
            try {
              return CustomColorSchemeModel.fromJson(json);
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                  reason: 'Failed to parse custom color scheme: $json');
              return null;
            }
          })
          .where((scheme) => scheme != null && !scheme.isDeleted)
          .cast<CustomColorSchemeModel>()
          .toList();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to load custom color schemes locally');
      return [];
    }
  }

  /// Get active custom color scheme
  Future<CustomColorSchemeModel?> getActiveScheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeSchemeJson = prefs.getString(_activeSchemeKey);

      if (activeSchemeJson != null) {
        return CustomColorSchemeModel.fromJson(activeSchemeJson);
      }
      return null;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to get active custom color scheme');
      return null;
    }
  }

  /// Set active custom color scheme
  Future<bool> setActiveScheme(CustomColorSchemeModel? scheme) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (scheme != null) {
        await prefs.setString(_activeSchemeKey, scheme.toJson());
      } else {
        await prefs.remove(_activeSchemeKey);
      }
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to set active custom color scheme');
      return false;
    }
  }

  /// Sync custom color scheme to Firebase
  Future<bool> syncToFirebase(CustomColorSchemeModel scheme) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update the scheme document in the user's custom color schemes collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('customColorSchemes')
          .doc(scheme.id)
          .set(scheme.toMap());

      // Mark as synced
      final updatedScheme = scheme.copyWith(
        isSynced: true,
        lastSyncedAt: DateTime.now(),
      );
      await saveLocalScheme(updatedScheme);

      return true;
    } catch (e) {
      // Handle permission denied gracefully - still save locally
      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('permission-denied')) {
        FirebaseCrashlytics.instance.log(
            'Custom color scheme sync failed due to permissions - saving locally only');

        // Still save locally even if sync fails
        await saveLocalScheme(scheme);
        return false; // Return false to indicate sync failed but local save succeeded
      }

      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync custom color scheme to Firebase');
      return false;
    }
  }

  /// Load custom color schemes from Firebase
  Future<List<CustomColorSchemeModel>> loadFromFirebase() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('customColorSchemes')
          .where('isDeleted', isEqualTo: false)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is set
        return CustomColorSchemeModel.fromMap(data);
      }).toList();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to load custom color schemes from Firebase');
      return [];
    }
  }

  /// Sync custom color schemes from Firebase to local
  Future<bool> syncFromFirebase() async {
    try {
      final cloudSchemes = await loadFromFirebase();

      // Save all cloud schemes locally
      for (final scheme in cloudSchemes) {
        await saveLocalScheme(scheme);
      }

      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync custom color schemes from Firebase');
      return false;
    }
  }

  /// Delete custom color scheme (hard deletion - removes from all storage)
  Future<bool> deleteScheme(CustomColorSchemeModel scheme) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Remove from Firebase first if it was synced
      if (scheme.isSynced) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('customColorSchemes')
            .doc(scheme.id)
            .delete();
      }

      // Only remove from local storage after successful remote deletion
      await _removeFromLocalStorage(scheme.id);

      // If this was the active scheme, clear it after local removal
      final activeScheme = await getActiveScheme();
      if (activeScheme?.id == scheme.id) {
        await setActiveScheme(null);
      }

      FirebaseCrashlytics.instance
          .log('Custom color scheme hard deleted: ${scheme.id}');
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to delete custom color scheme');
      return false;
    }
  }

  /// Remove scheme from local storage completely
  Future<void> _removeFromLocalStorage(String schemeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schemesJson = prefs.getStringList(_prefsKey) ?? [];

      // Filter out the scheme to be deleted
      final updatedSchemes = schemesJson.where((json) {
        try {
          final scheme = CustomColorSchemeModel.fromJson(json);
          return scheme.id != schemeId;
        } catch (e) {
          FlutterBugfender.sendCrash(
              'Failed to remove scheme from local storage: $e',
              StackTrace.current.toString());
          return true;
        }
      }).toList();

      // Update SharedPreferences with filtered list
      await prefs.setStringList(_prefsKey, updatedSchemes);
      FlutterBugfender.sendCrash('Removed scheme $schemeId from local storage',
          StackTrace.current.toString());
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to remove scheme from local storage: $e',
          StackTrace.current.toString());
      rethrow;
    }
  }

  /// Create new custom color scheme
  Future<CustomColorSchemeModel?> createScheme({
    required String name,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color textColor,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final scheme = CustomColorSchemeModel(
        id: CustomColorSchemeModel.generateId(),
        userId: userId,
        name: name,
        primary: primary,
        secondary: secondary,
        background: background,
        textColor: textColor,
      );

      // Save locally first
      await saveLocalScheme(scheme);

      // Try to sync to Firebase (may fail due to permissions)
      final syncSuccess = await syncToFirebase(scheme);

      if (!syncSuccess) {
        // Sync failed but local save succeeded - this is still a success
        FirebaseCrashlytics.instance.log(
            'Custom color scheme created locally (sync failed due to permissions)');
      }

      return scheme;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to create custom color scheme');
      return null;
    }
  }

  /// Update existing custom color scheme
  Future<bool> updateScheme(CustomColorSchemeModel scheme) async {
    try {
      // Save locally first
      await saveLocalScheme(scheme);

      // Sync to Firebase if synced
      if (scheme.isSynced) {
        await syncToFirebase(scheme);
      }

      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to update custom color scheme');
      return false;
    }
  }

  /// Sync all local schemes to Firebase
  Future<bool> syncAllToFirebase() async {
    try {
      final localSchemes = await loadLocalSchemes();
      bool allSynced = true;

      for (final scheme in localSchemes) {
        if (scheme.shouldSync) {
          final success = await syncToFirebase(scheme);
          if (!success) allSynced = false;
        }
      }

      return allSynced;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync all custom color schemes to Firebase');
      return false;
    }
  }

  /// Clear all local custom color schemes
  Future<bool> clearAllLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.remove(_activeSchemeKey);
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to clear all local custom color schemes');
      return false;
    }
  }

  /// Clean up any orphaned or corrupted data
  Future<void> cleanupOrphanedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schemesJson = prefs.getStringList(_prefsKey) ?? [];

      // Filter out any corrupted or invalid schemes
      final validSchemes = schemesJson.where((json) {
        try {
          final scheme = CustomColorSchemeModel.fromJson(json);
          // Keep only valid, non-deleted schemes
          return scheme.id.isNotEmpty &&
              scheme.name.isNotEmpty &&
              !scheme.isDeleted;
        } catch (e) {
          // Remove corrupted entries
          FirebaseCrashlytics.instance
              .log('Removing corrupted scheme data: $json');
          return false;
        }
      }).toList();

      // Update SharedPreferences with cleaned data
      if (validSchemes.length != schemesJson.length) {
        await prefs.setStringList(_prefsKey, validSchemes);
        FirebaseCrashlytics.instance.log(
            'Cleaned up ${schemesJson.length - validSchemes.length} orphaned schemes');
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to cleanup orphaned data');
    }
  }
}
