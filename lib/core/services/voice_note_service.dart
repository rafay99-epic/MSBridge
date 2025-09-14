import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/repo/voice_note_repo.dart';
import 'package:uuid/uuid.dart';

class VoiceNoteService {
  static const String _voiceNotesFolder = 'voice_notes';
  static const _uuid = Uuid();

  VoiceNoteService._();

  static final VoiceNoteService _instance = VoiceNoteService._();

  factory VoiceNoteService() => _instance;

  Future<Directory> getVoiceNotesDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final voiceNotesDir = Directory('${appDir.path}/$_voiceNotesFolder');

      if (!await voiceNotesDir.exists()) {
        await voiceNotesDir.create(recursive: true);
      }

      return voiceNotesDir;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error getting voice notes directory: $e',
      );
      throw Exception('Error getting voice notes directory: $e');
    }
  }

  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        return false;
      }

      return false;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error requesting microphone permission: $e',
      );
      return false;
    }
  }

  Future<VoiceNoteModel> saveVoiceNote({
    required String audioFilePath,
    required String title,
    required String userId,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final voiceNotesDir = await getVoiceNotesDirectory();
      final voiceNoteId = _uuid.v4();
      final fileName = '$voiceNoteId.m4a';
      final destinationPath = '${voiceNotesDir.path}/$fileName';

      final sourceFile = File(audioFilePath);

      if (await sourceFile.exists()) {
        File destinationFile;

        // Try rename first for better performance
        try {
          await sourceFile.rename(destinationPath);
          destinationFile = File(destinationPath);
        } catch (e) {
          // Fall back to copy if rename fails
          await sourceFile.copy(destinationPath);
          destinationFile = File(destinationPath);

          // Best-effort delete of original file (don't throw if it fails)
          if (audioFilePath != destinationPath && await sourceFile.exists()) {
            try {
              await sourceFile.delete();
            } catch (deleteError) {
              FirebaseCrashlytics.instance.recordError(
                deleteError,
                StackTrace.current,
                reason:
                    'Error deleting original audio file after copy: $deleteError',
              );
              // Don't rethrow - continue with saved state
            }
          }
        }

        final fileStat = await destinationFile.stat();
        final fileSize = fileStat.size;

        final duration = await _getAudioDuration(destinationPath);

        final voiceNote = VoiceNoteModel(
          voiceNoteId: voiceNoteId,
          voiceNoteTitle: title,
          audioFilePath: destinationPath,
          durationInSeconds: duration,
          fileSizeInBytes: fileSize,
          userId: userId,
          description: description,
          tags: tags ?? [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await VoiceNoteRepo.addVoiceNote(voiceNote);

        return voiceNote;
      } else {
        throw Exception('Source audio file does not exist: $audioFilePath');
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error saving voice note: $e',
      );
      throw Exception('Error saving voice note: $e');
    }
  }

  Future<int> _getAudioDuration(String filePath) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();

      final estimatedDuration = (fileSize / (128 * 1024 / 8)).round();
      return estimatedDuration.clamp(1, 3600);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error getting audio duration: $e',
      );
      return 30;
    }
  }

  Future<void> deleteVoiceNote(VoiceNoteModel voiceNote) async {
    try {
      final audioFile = File(voiceNote.audioFilePath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      } else {
        FlutterBugfender.sendCrash(
            'Audio file does not exist at path: ${voiceNote.audioFilePath}',
            StackTrace.current.toString());
        throw Exception(
            'Audio file does not exist at path: ${voiceNote.audioFilePath}');
      }

      await VoiceNoteRepo.deleteVoiceNote(voiceNote);

      await _verifyDeletion(voiceNote);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error deleting voice note: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error deleting voice note: $e',
      );
      throw Exception('Error deleting voice note: $e');
    }
  }

  Future<void> _verifyDeletion(VoiceNoteModel voiceNote) async {
    try {
      final audioFile = File(voiceNote.audioFilePath);
      final audioFileExists = await audioFile.exists();

      final metadataExists = voiceNote.voiceNoteId != null &&
          await VoiceNoteRepo.getVoiceNoteById(voiceNote.voiceNoteId!) != null;

      if (audioFileExists) {
        FirebaseCrashlytics.instance.recordError(
          Exception('Audio file still exists after deletion!'),
          StackTrace.current,
          reason: 'Audio file still exists after deletion!',
        );
        throw Exception('Audio file still exists after deletion!');
      }

      if (metadataExists) {
        FirebaseCrashlytics.instance.recordError(
          Exception('Metadata still exists after deletion!'),
          StackTrace.current,
          reason: 'Metadata still exists after deletion!',
        );
        throw Exception('Metadata still exists after deletion!');
      }

      if (!audioFileExists && !metadataExists) {
        FirebaseCrashlytics.instance.recordError(
          Exception('Both audio file and metadata successfully deleted'),
          StackTrace.current,
          reason: 'Both audio file and metadata successfully deleted',
        );
        throw Exception('Both audio file and metadata successfully deleted');
      } else {
        FirebaseCrashlytics.instance.recordError(
          Exception('Some data still exists after deletion'),
          StackTrace.current,
          reason: 'Some data still exists after deletion',
        );
        throw Exception('Some data still exists after deletion');
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during verification: $e',
      );
      throw Exception('Error during verification: $e');
    }
  }

  Future<void> updateVoiceNoteMetadata({
    required VoiceNoteModel voiceNote,
    String? title,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final updatedVoiceNote = voiceNote.copyWith(
        voiceNoteTitle: title ?? voiceNote.voiceNoteTitle,
        description: description ?? voiceNote.description,
        tags: tags ?? voiceNote.tags,
        updatedAt: DateTime.now(),
      );

      await VoiceNoteRepo.updateVoiceNote(updatedVoiceNote);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error updating voice note metadata: $e',
      );
      throw Exception('Error updating voice note metadata: $e');
    }
  }

  Future<bool> audioFileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<int> getTotalStorageUsed() async {
    try {
      final voiceNotesDir = await getVoiceNotesDirectory();
      int totalSize = 0;

      await for (final entity in voiceNotesDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error calculating total storage used: $e',
      );
      return 0;
    }
  }

  Future<void> cleanupOrphanedFiles() async {
    try {
      final voiceNotesDir = await getVoiceNotesDirectory();
      final allVoiceNotes = await VoiceNoteRepo.getAllVoiceNotes();
      final referencedFiles =
          allVoiceNotes.map((note) => note.audioFilePath).toSet();

      await for (final entity in voiceNotesDir.list()) {
        if (entity is File) {
          if (!referencedFiles.contains(entity.path)) {
            try {
              await entity.delete();
              FirebaseCrashlytics.instance.recordError(
                Exception('Deleted orphaned file: ${entity.path}'),
                StackTrace.current,
                reason: 'Deleted orphaned file: ${entity.path}',
              );
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                Exception('Could not delete orphaned file ${entity.path}: $e'),
                StackTrace.current,
                reason: 'Could not delete orphaned file ${entity.path}: $e',
              );
            }
          }
        }
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error cleaning up orphaned files: $e',
      );
    }
  }

  String formatStorageSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  Future<String?> exportVoiceNote(
      VoiceNoteModel voiceNote, String exportPath) async {
    try {
      final sourceFile = File(voiceNote.audioFilePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source audio file does not exist');
      }

      await sourceFile.copy(exportPath);

      return exportPath;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error exporting voice note: $e',
      );
      throw Exception('Error exporting voice note: $e');
    }
  }
}
