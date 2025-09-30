// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/template_repo.dart';

/// Syncs local templates with Firebase under users/{uid}/templates/{templateId}
class TemplatesSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepo _authRepo = AuthRepo();

  Future<void> startListening() async {
    try {
      // Check global sync toggle before syncing
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;

      // Ensure templates box is ready
      await TemplateRepo.getBox();

      await syncLocalTemplatesToFirebase();
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Error starting templates sync');
    }
  }

  Future<bool> _isCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final global = prefs.getBool('cloud_sync_enabled') ?? true;
    final templatesSpecific =
        prefs.getBool('templates_cloud_sync_enabled') ?? true;
    final templatesFeatureEnabled = prefs.getBool('templates_enabled') ?? true;
    return global && templatesSpecific && templatesFeatureEnabled;
  }

  Future<User?> _getCurrentUser() async {
    final result = await _authRepo.getCurrentUser();
    return result.user;
  }

  Future<void> syncLocalTemplatesToFirebase() async {
    try {
      // Ensure box is ready in background isolate too
      await TemplateRepo.getBox();
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;

      final user = await _getCurrentUser();
      if (user == null) return;
      final String userId = user.uid;

      final List<NoteTemplate> templates = await TemplateRepo.getTemplates();
      final CollectionReference<Map<String, dynamic>> col =
          _firestore.collection('users').doc(userId).collection('templates');

      for (final t in templates) {
        try {
          if (t.isBuiltIn) continue; // do not sync built-in templates
          final data = <String, dynamic>{
            'templateId': t.templateId,
            'title': t.title,
            'contentJson': t.contentJson,
            'tags': t.tags,
            'userId': userId,
            'createdAt': t.createdAt.toIso8601String(),
            'updatedAt': t.updatedAt.toIso8601String(),
            'isBuiltIn': t.isBuiltIn,
            'syncedAt': DateTime.now().toIso8601String(),
          };
          await col.doc(t.templateId).set(data, SetOptions(merge: true));
        } catch (e, st) {
          FirebaseCrashlytics.instance.recordError(
            e,
            st,
            reason: 'Template sync failed for ${t.templateId}',
          );
        }
      }
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'General templates sync error');
    }
  }

  /// Best-effort immediate cloud delete; respects the user's cloud sync setting.
  Future<void> deleteTemplateInCloud(String templateId) async {
    try {
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;
      final user = await _getCurrentUser();
      if (user == null) return;

      final DocumentReference<Map<String, dynamic>> doc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('templates')
          .doc(templateId);
      await doc.delete();
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Failed to delete template in cloud');
    }
  }

  /// Pull templates from cloud into local Hive. Returns number of templates pulled/updated.
  Future<int> pullTemplatesFromCloud() async {
    int imported = 0;
    try {
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return 0;
      final user = await _getCurrentUser();
      if (user == null) return 0;

      final col =
          _firestore.collection('users').doc(user.uid).collection('templates');
      final snapshot = await col.get();
      final box = await TemplateRepo.getBox();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        try {
          final t = NoteTemplate(
            templateId: data['templateId'] ?? doc.id,
            title: data['title'] ?? '',
            contentJson: data['contentJson'] ?? '',
            tags: (data['tags'] as List?)?.cast<String>() ?? const [],
            userId: data['userId'] as String?,
            createdAt:
                DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
            updatedAt:
                DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
            isBuiltIn: data['isBuiltIn'] ?? false,
          );
          await box.put(t.templateId, t);
          imported++;
        } catch (e, st) {
          FirebaseCrashlytics.instance.recordError(
            e,
            st,
            reason: 'Failed to import template ${doc.id}',
          );
        }
      }
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Failed pulling templates');
    }
    return imported;
  }
}
