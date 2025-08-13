import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/utils/uuid.dart';

class ShareRepository {
  static const String _shareCollection = 'shared_notes';
  static const String _shareMetaBoxName = 'note_share_meta';

  static Future<Box> _getShareMetaBox() async {
    return await Hive.openBox(_shareMetaBoxName);
    
  }

  static String _buildDefaultShareUrl(String shareId) {
    // Default to Firebase Hosting-like URL path; replace with your custom domain if available
    return 'https://msbridge-9a2c7.web.app/s/$shareId';
  }

  static Future<String> enableShare(NoteTakingModel note) async {
    if (note.noteId == null || note.noteId!.isEmpty) {
      throw Exception('Note must be saved before sharing.');
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to enable sharing.');
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final Box meta = await _getShareMetaBox();

    // Reuse existing shareId if present
    final Map? existing = meta.get(note.noteId) as Map?;
    final String shareId = existing != null && existing['shareId'] is String && (existing['shareId'] as String).isNotEmpty
        ? existing['shareId'] as String
        : generateUuid();

    final String shareUrl = _buildDefaultShareUrl(shareId);

    final Map<String, dynamic> payload = {
      'shareId': shareId,
      'noteId': note.noteId,
      'title': note.noteTitle,
      'content': note.noteContent,
      'ownerUid': user.uid,
      'updatedAt': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'viewOnly': true,
      'shareUrl': shareUrl,
    };

    await firestore.collection(_shareCollection).doc(shareId).set(payload, SetOptions(merge: true));

    await meta.put(note.noteId, {
      'shareId': shareId,
      'enabled': true,
      'shareUrl': shareUrl,
      'title': note.noteTitle,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return shareUrl;
  }

  static Future<void> disableShare(NoteTakingModel note) async {
    if (note.noteId == null || note.noteId!.isEmpty) return;

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final Box meta = await _getShareMetaBox();
    final Map? existing = meta.get(note.noteId) as Map?;
    final String? shareId = existing != null ? existing['shareId'] as String? : null;

    if (shareId != null && shareId.isNotEmpty) {
      await firestore.collection(_shareCollection).doc(shareId).delete().catchError((_) {});
    }

    await meta.put(note.noteId, {
      'shareId': shareId ?? '',
      'enabled': false,
      'shareUrl': '',
      'title': note.noteTitle,
      'updatedAt': DateTime.now().toIso8601String(),
    });
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
    result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return result;
  }

  static Future<SharedStatus> getShareStatus(String noteId) async {
    final Box meta = await _getShareMetaBox();
    final Map? data = meta.get(noteId) as Map?;
    if (data == null) return const SharedStatus(enabled: false, shareUrl: '', shareId: '');
    return SharedStatus(
      enabled: (data['enabled'] as bool?) ?? false,
      shareUrl: (data['shareUrl'] as String?) ?? '',
      shareId: (data['shareId'] as String?) ?? '',
    );
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

  const SharedStatus({required this.enabled, required this.shareUrl, required this.shareId});
}
