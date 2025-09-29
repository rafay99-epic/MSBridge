import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/services/upload/uploadthing_service.dart';
import 'package:msbridge/config/config.dart';
import 'package:msbridge/utils/uuid.dart';
import 'package:msbridge/core/services/dynamic_link/dynamic_link.dart';
import 'package:msbridge/config/config.dart' as config;

class VoiceNoteShareRepository {
  static const String _shareCollection = 'shared_voice_notes';
  static const String _shareMetaBoxName = 'voice_note_share_meta';
  static bool _isOperationInProgress = false;

  static Future<Box> _getShareMetaBox() async {
    return await Hive.openBox(_shareMetaBoxName);
  }

  static String _buildDefaultShareUrl(String shareId) {
    final String base = config.UpdateConfig.mode == 'production'
        ? config.LinkShortenerConfig.prodBaseUrl
        : config.LinkShortenerConfig.devBaseUrl;
    return '$base/voice/$shareId';
  }

  static Future<String> _buildShortLink(String shareId) async {
    return ShortLinkService.generateShortLink(
      type: 'voice',
      shareId: shareId,
      originalUrl: _buildDefaultShareUrl(shareId),
    );
  }

  static Future<String> enableShare(VoiceNoteModel voiceNote) async {
    if (_isOperationInProgress) {
      FlutterBugfender.error(
          'Voice note share operation already in progress. Please wait.');
      throw Exception(
          'Voice note share operation already in progress. Please wait.');
    }

    if (voiceNote.voiceNoteId == null || voiceNote.voiceNoteId!.isEmpty) {
      throw Exception('Voice note must be saved before sharing.');
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to enable sharing.');
    }

    _isOperationInProgress = true;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final Box meta = await _getShareMetaBox();
      final UploadThingService uploadService =
          UploadThingService(apiKey: UploadThingConfig.apiKey);

      // Reuse existing shareId if present
      final Map? existing = meta.get(voiceNote.voiceNoteId) as Map?;
      final String shareId = existing != null &&
              existing['shareId'] is String &&
              (existing['shareId'] as String).isNotEmpty
          ? existing['shareId'] as String
          : generateUuid();

      final audioFile = File(voiceNote.audioFilePath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found: ${voiceNote.audioFilePath}');
      }

      final String audioUrl = await uploadService.uploadAudioFile(audioFile);

      final String shareUrl = await _buildShortLink(shareId);

      // Create payload for Firebase
      final Map<String, dynamic> payloadWithoutCreatedAt = {
        'shareId': shareId,
        'voiceNoteId': voiceNote.voiceNoteId,
        'title': voiceNote.voiceNoteTitle,
        'description': voiceNote.description ?? '',
        'audioUrl': audioUrl,
        'duration': voiceNote.durationInSeconds,
        'fileSize': voiceNote.fileSizeInBytes,
        'ownerUid': user.uid,
        'ownerEmail': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'viewOnly': true,
        'shareUrl': shareUrl,
      };

      final Map<String, dynamic> payloadWithCreatedAt = {
        ...payloadWithoutCreatedAt,
        'createdAt': FieldValue.serverTimestamp(),
      };
      final docRef = firestore.collection(_shareCollection).doc(shareId);
      try {
        await docRef.update(payloadWithoutCreatedAt);
      } on FirebaseException catch (e, s) {
        if (e.code == 'not-found') {
          await docRef.set(payloadWithCreatedAt, SetOptions(merge: true));
        } else {
          FlutterBugfender.error(
              'Failed to update voice note share: ${e.code} ${e.message}');
          FlutterBugfender.sendCrash('enableShare update failed', s.toString());
          rethrow;
        }
      }

      await meta.put(voiceNote.voiceNoteId, {
        'shareId': shareId,
        'enabled': true,
        'shareUrl': shareUrl,
        'title': voiceNote.voiceNoteTitle,
        'audioUrl': audioUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return shareUrl;
    } finally {
      _isOperationInProgress = false;
    }
  }

  static Future<void> disableShare(VoiceNoteModel voiceNote) async {
    if (_isOperationInProgress) {
      throw Exception(
          'Voice note share operation already in progress. Please wait.');
    }

    if (voiceNote.voiceNoteId == null || voiceNote.voiceNoteId!.isEmpty) return;

    _isOperationInProgress = true;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final Box meta = await _getShareMetaBox();
      final Map? existing = meta.get(voiceNote.voiceNoteId) as Map?;
      final String? shareId =
          existing != null ? existing['shareId'] as String? : null;

      if (shareId != null && shareId.isNotEmpty) {
        try {
          await firestore.collection(_shareCollection).doc(shareId).delete();
        } catch (error) {
          FlutterBugfender.error(
            'Failed to delete voice note share $shareId and error: $error',
          );
          FlutterBugfender.sendCrash(
              'Failed to delete voice note share $shareId and error: $error',
              error.toString());
          rethrow;
        }
      }

      await meta.put(voiceNote.voiceNoteId, {
        'shareId': shareId ?? '',
        'enabled': false,
        'shareUrl': '',
        'title': voiceNote.voiceNoteTitle,
        'audioUrl': '',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } finally {
      _isOperationInProgress = false;
    }
  }

  static Future<List<SharedVoiceNoteMeta>> getSharedVoiceNotes() async {
    final Box meta = await _getShareMetaBox();
    final List<SharedVoiceNoteMeta> result = [];
    for (final key in meta.keys) {
      final Map? data = meta.get(key) as Map?;
      if (data == null) continue;
      final bool enabled = (data['enabled'] as bool?) ?? false;
      if (!enabled) continue;
      result.add(
        SharedVoiceNoteMeta(
          voiceNoteId: key.toString(),
          shareId: (data['shareId'] as String?) ?? '',
          shareUrl: (data['shareUrl'] as String?) ?? '',
          title: (data['title'] as String?) ?? '',
          audioUrl: (data['audioUrl'] as String?) ?? '',
        ),
      );
    }
    result
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return result;
  }

  static Future<SharedVoiceNoteStatus> getShareStatus(
      String voiceNoteId) async {
    final Box meta = await _getShareMetaBox();
    final Map? data = meta.get(voiceNoteId) as Map?;
    if (data == null) {
      return const SharedVoiceNoteStatus(
          enabled: false, shareUrl: '', shareId: '', audioUrl: '');
    }
    return SharedVoiceNoteStatus(
      enabled: (data['enabled'] as bool?) ?? false,
      shareUrl: (data['shareUrl'] as String?) ?? '',
      shareId: (data['shareId'] as String?) ?? '',
      audioUrl: (data['audioUrl'] as String?) ?? '',
    );
  }
}

class SharedVoiceNoteMeta {
  final String voiceNoteId;
  final String shareId;
  final String shareUrl;
  final String title;
  final String audioUrl;

  SharedVoiceNoteMeta({
    required this.voiceNoteId,
    required this.shareId,
    required this.shareUrl,
    required this.title,
    required this.audioUrl,
  });
}

class SharedVoiceNoteStatus {
  final bool enabled;
  final String shareUrl;
  final String shareId;
  final String audioUrl;

  const SharedVoiceNoteStatus({
    required this.enabled,
    required this.shareUrl,
    required this.shareId,
    required this.audioUrl,
  });
}
