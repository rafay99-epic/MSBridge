import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:msbridge/core/database/note_taking/note_version.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/note_version_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VersionSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepo _authRepo = AuthRepo();

  /// Sync local versions to Firebase
  Future<void> syncLocalVersionsToFirebase() async {
    try {
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;

      final user = await _getCurrentUser();
      if (user == null) return;

      final userId = user.uid;
      final allVersions = await NoteVersionRepo.getAllVersions();

      // Filter versions for current user
      final userVersions =
          allVersions.where((v) => v.userId == userId).toList();

      for (final version in userVersions) {
        await _syncVersionToFirebase(version, userId);
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error syncing versions to Firebase");
      throw Exception("Error syncing versions to Firebase: $e");
    }
  }

  /// Sync versions from Firebase to local
  Future<void> syncVersionsFromFirebaseToLocal() async {
    try {
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;

      final user = await _getCurrentUser();
      if (user == null) return;

      final userId = user.uid;

      final QuerySnapshot versionsSnapshot = await _firestore
          .collectionGroup('versions')
          .where('userId', isEqualTo: userId)
          .get();

      if (versionsSnapshot.docs.isEmpty) return;

      // Clear existing local versions for this user
      await NoteVersionRepo.clearVersionsForUser(userId);

      // Import versions from Firebase
      for (final doc in versionsSnapshot.docs) {
        final raw = doc.data() as Map<String, dynamic>;
        // Ensure versionId (doc id) and noteId (parent) are set in the payload
        final String? noteIdFromPath = doc.reference.parent.parent?.id;
        final Map<String, dynamic> data = {
          ...raw,
          'versionId': raw['versionId'] ?? doc.id,
          if (noteIdFromPath != null) 'noteId': raw['noteId'] ?? noteIdFromPath,
        };
        await _importVersionFromFirebase(data, userId);
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error syncing versions from Firebase");
      throw Exception("Error syncing versions from Firebase: $e");
    }
  }

  /// Sync a single version to Firebase
  Future<void> _syncVersionToFirebase(
      NoteVersion version, String userId) async {
    try {
      // Store under users/{userId}/notes/{noteId}/versions/{versionId}
      final noteId = version.noteId;
      if (noteId.isEmpty) {
        FirebaseCrashlytics.instance.log(
            'Skipping version push: missing noteId for versionId=${version.versionId}');
        return; // skip bad record
      }
      final versionsCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .collection('versions');

      final versionData = version.toMap();
      versionData['syncedAt'] = FieldValue.serverTimestamp();

      await versionsCollection
          .doc(version.versionId)
          .set(versionData, SetOptions(merge: true));
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error syncing version ${version.versionId} to Firebase");
      throw Exception("Error syncing version to Firebase: $e");
    }
  }

  /// Import a version from Firebase
  Future<void> _importVersionFromFirebase(
      Map<String, dynamic> data, String userId) async {
    try {
      // Validate required fields before creating version
      final noteId = data['noteId'];
      if (noteId == null || noteId.toString().isEmpty) {
        return;
      }

      final version = NoteVersion.fromMap(data);

      // Ensure the version belongs to the current user
      if (version.userId != userId) return;

      // Check if version already exists locally
      if (version.versionId != null) {
        final existingVersion =
            await NoteVersionRepo.getVersion(version.versionId!);
        if (existingVersion != null) {
          // Update existing version
          await NoteVersionRepo.updateVersion(version);
        } else {
          // Create new version with validated noteId
          final validatedNoteId = noteId.toString();
          await NoteVersionRepo.createVersion(
            noteId: validatedNoteId,
            noteTitle: version.noteTitle,
            noteContent: version.noteContent,
            tags: version.tags,
            userId: version.userId,
            versionNumber: version.versionNumber,
            changeDescription: version.changeDescription,
            previousVersionId: version.previousVersionId,
          );
        }
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error importing version from Firebase");
      // Continue with other versions
    }
  }

  /// Clean up versions for deleted notes
  Future<void> cleanupVersionsForDeletedNotes(
      List<String> deletedNoteIds) async {
    try {
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;

      final user = await _getCurrentUser();
      if (user == null) return;

      final userId = user.uid;

      // Clean up local versions
      for (final noteId in deletedNoteIds) {
        await NoteVersionRepo.clearVersionsForNote(noteId);
      }

      // Clean up Firebase versions under nested path (chunked to 500 ops max)
      WriteBatch batch = _firestore.batch();
      int opCount = 0;
      Future<void> commitIfNeeded() async {
        if (opCount >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      for (final noteId in deletedNoteIds) {
        final versionsRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notes')
            .doc(noteId)
            .collection('versions');
        final snap = await versionsRef.get();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
          opCount++;
          await commitIfNeeded();
        }
      }
      if (opCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error cleaning up versions for deleted notes");
      throw Exception("Error cleaning up versions for deleted notes: $e");
    }
  }

  /// Sync versions when a note is updated
  Future<void> syncNoteVersions(String noteId, String userId) async {
    try {
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;

      // Get all versions for this note
      final versions = await NoteVersionRepo.getNoteVersions(noteId);

      // Sync each version to Firebase
      for (final version in versions) {
        await _syncVersionToFirebase(version, userId);
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error syncing note versions");
      throw Exception("Error syncing note versions: $e");
    }
  }

  /// Check if cloud sync is enabled
  Future<bool> _isCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('cloud_sync_enabled') ?? true;
  }

  /// Get current authenticated user
  Future<User?> _getCurrentUser() async {
    try {
      final authResult = await _authRepo.getCurrentUser();
      return authResult.user;
    } catch (e) {
      return null;
    }
  }

  /// Get sync status for versions
  Future<Map<String, dynamic>> getVersionSyncStatus() async {
    try {
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) {
        return {
          'enabled': false,
          'message': 'Cloud sync is disabled',
          'localVersions': 0,
          'cloudVersions': 0,
        };
      }

      final user = await _getCurrentUser();
      if (user == null) {
        return {
          'enabled': false,
          'message': 'User not authenticated',
          'localVersions': 0,
          'cloudVersions': 0,
        };
      }

      final userId = user.uid;
      final localVersions = await NoteVersionRepo.getTotalVersionCount();

      // Get cloud versions count via collection group
      final cloudSnapshot = await _firestore
          .collectionGroup('versions')
          .where('userId', isEqualTo: userId)
          .get();
      final cloudVersions = cloudSnapshot.docs.length;

      return {
        'enabled': true,
        'message': 'Cloud sync is enabled',
        'localVersions': localVersions,
        'cloudVersions': cloudVersions,
        'synced': localVersions == cloudVersions,
      };
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error getting version sync status");
      return {
        'enabled': false,
        'message': 'Error: $e',
        'localVersions': 0,
        'cloudVersions': 0,
      };
    }
  }

  Future<void> pruneCloudVersions({
    required String userId,
    required String noteId,
    required int keepLatest,
  }) async {
    try {
      final versionsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .collection('versions');

      final snapshot =
          await versionsRef.orderBy('versionNumber', descending: true).get();

      if (snapshot.docs.length <= keepLatest) return;
      final toDelete = snapshot.docs.skip(keepLatest);
      final batch = _firestore.batch();
      for (final doc in toDelete) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st,
          reason: 'Failed pruning cloud versions for noteId=$noteId');
    }
  }
}
