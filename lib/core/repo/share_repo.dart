// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:msbridge/config/config.dart' as config;
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/services/dynamic_link/dynamic_link.dart';
import 'package:msbridge/utils/uuid.dart';

class DynamicLink {
  static const String _shareCollection = 'shared_notes';
  static const String _shareMetaBoxName = 'note_share_meta';
  static bool _isOperationInProgress = false;
  static Future<Box> _getShareMetaBox() async {
    return await Hive.openBox(_shareMetaBoxName);
  }

  static String _buildDefaultShareUrl(String shareId) {
    final String base = config.UpdateConfig.mode == 'production'
        ? config.LinkShortenerConfig.prodBaseUrl
        : config.LinkShortenerConfig.devBaseUrl;
    return '$base/s/$shareId';
  }

  static Future<String> _buildShortLink(String shareId) async {
    return ShortLinkService.generateShortLink(
      type: 'note',
      shareId: shareId,
      originalUrl: _buildDefaultShareUrl(shareId),
    );
  }

  static Future<String> enableShare(NoteTakingModel note) async {
    if (_isOperationInProgress) {
      FlutterBugfender.error(
          'Share operation already in progress. Please wait.');
      throw Exception('Share operation already in progress. Please wait.');
    }

    if (note.noteId == null || note.noteId!.isEmpty) {
      throw Exception('Note must be saved before sharing.');
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to enable sharing.');
    }

    _isOperationInProgress = true;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final Box meta = await _getShareMetaBox();

      // Reuse existing shareId if present
      final Map? existing = meta.get(note.noteId) as Map?;
      final String shareId = existing != null &&
              existing['shareId'] is String &&
              (existing['shareId'] as String).isNotEmpty
          ? existing['shareId'] as String
          : generateUuid();

      final String shareUrl = await _buildShortLink(shareId);

      // Create payload without createdAt for updates
      final Map<String, dynamic> payloadWithoutCreatedAt = {
        'shareId': shareId,
        'noteId': note.noteId,
        'title': note.noteTitle,
        'content': note.noteContent,
        'ownerUid': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'viewOnly': true,
        'shareUrl': shareUrl,
      };

      // Create payload with createdAt for new documents
      final Map<String, dynamic> payloadWithCreatedAt = {
        ...payloadWithoutCreatedAt,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Try update first; on not-found create with createdAt.
      final docRef = firestore.collection(_shareCollection).doc(shareId);
      try {
        await docRef.update(payloadWithoutCreatedAt);
      } on FirebaseException catch (e, s) {
        if (e.code == 'not-found') {
          await docRef.set(payloadWithCreatedAt, SetOptions(merge: true));
        } else {
          FlutterBugfender.error(
              'Failed to update share: ${e.code} ${e.message}');
          FlutterBugfender.sendCrash('enableShare update failed', s.toString());
          rethrow;
        }
      }

      await meta.put(note.noteId, {
        'shareId': shareId,
        'enabled': true,
        'shareUrl': shareUrl,
        'title': note.noteTitle,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return shareUrl;
    } finally {
      _isOperationInProgress = false;
    }
  }

  static Future<void> disableShare(NoteTakingModel note) async {
    if (_isOperationInProgress) {
      throw Exception('Share operation already in progress. Please wait.');
    }

    if (note.noteId == null || note.noteId!.isEmpty) return;

    _isOperationInProgress = true;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final Box meta = await _getShareMetaBox();
      final Map? existing = meta.get(note.noteId) as Map?;
      final String? shareId =
          existing != null ? existing['shareId'] as String? : null;

      if (shareId != null && shareId.isNotEmpty) {
        try {
          await firestore.collection(_shareCollection).doc(shareId).delete();
        } catch (error) {
          FlutterBugfender.error(
            'Failed to delete share $shareId and error: $error',
          );
          FlutterBugfender.sendCrash(
              'Failed to delete share $shareId and error: $error',
              error.toString());
          rethrow;
        }
      }

      await meta.put(note.noteId, {
        'shareId': shareId ?? '',
        'enabled': false,
        'shareUrl': '',
        'title': note.noteTitle,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } finally {
      _isOperationInProgress = false;
    }
  }

  static Future<List<SharedNoteMeta>> getSharedNotes() async {
    final Box meta = await _getShareMetaBox();
    final List<SharedNoteMeta> result = [];
    for (final key in meta.keys) {
      final Map? data = meta.get(key) as Map?;
      if (data == null) continue;
      final bool enabled = (data['enabled'] as bool?) ?? false;
      if (!enabled) continue;
      result.add(
        SharedNoteMeta(
          noteId: key.toString(),
          shareId: (data['shareId'] as String?) ?? '',
          shareUrl: (data['shareUrl'] as String?) ?? '',
          title: (data['title'] as String?) ?? '',
        ),
      );
    }
    // Sort by title for stable UX
    result
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return result;
  }

  static Future<SharedStatus> getShareStatus(String noteId) async {
    final Box meta = await _getShareMetaBox();
    final Map? data = meta.get(noteId) as Map?;
    if (data == null) {
      return const SharedStatus(enabled: false, shareUrl: '', shareId: '');
    }
    return SharedStatus(
      enabled: (data['enabled'] as bool?) ?? false,
      shareUrl: (data['shareUrl'] as String?) ?? '',
      shareId: (data['shareId'] as String?) ?? '',
    );
  }

  static Future<void> disableAllShares() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final Box meta = await _getShareMetaBox();
    final List<dynamic> keys = meta.keys.toList(growable: false);
    for (final key in keys) {
      final Map? data = meta.get(key) as Map?;
      if (data == null) continue;
      final bool enabled = (data['enabled'] as bool?) ?? false;
      final String? shareId = data['shareId'] as String?;
      if (!enabled) continue;
      if (shareId != null && shareId.isNotEmpty) {
        try {
          await firestore.collection(_shareCollection).doc(shareId).delete();
        } catch (error) {
          FlutterBugfender.error(
            'Failed to delete share $shareId and error: $error',
          );
          FlutterBugfender.sendCrash(
              'Failed to delete share $shareId and error: $error',
              error.toString());
          rethrow;
        }
      }
      await meta.put(key, {
        'shareId': shareId ?? '',
        'enabled': false,
        'shareUrl': '',
        'title': (data['title'] as String?) ?? '',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }
}

class SharedNoteMeta {
  final String noteId;
  final String shareId;
  final String shareUrl;
  final String title;

  SharedNoteMeta({
    required this.noteId,
    required this.shareId,
    required this.shareUrl,
    required this.title,
  });
}

class SharedStatus {
  final bool enabled;
  final String shareUrl;
  final String shareId;

  const SharedStatus(
      {required this.enabled, required this.shareUrl, required this.shareId});
}
