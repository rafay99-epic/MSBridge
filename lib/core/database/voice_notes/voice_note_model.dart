// Package imports:
import 'package:hive/hive.dart';

part 'voice_note_model.g.dart';

@HiveType(typeId: 15)
class VoiceNoteModel extends HiveObject {
  @HiveField(0)
  String? voiceNoteId;

  @HiveField(1)
  String voiceNoteTitle;

  @HiveField(2)
  String audioFilePath;

  @HiveField(3)
  int durationInSeconds;

  @HiveField(4)
  int fileSizeInBytes;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  String userId;

  @HiveField(8)
  bool isSynced;

  @HiveField(9)
  bool isDeleted;

  @HiveField(10)
  List<String> tags;

  @HiveField(11)
  String? description;

  @HiveField(12)
  DateTime? deletedAt;

  @HiveField(13)
  String? deletedBy;

  @HiveField(14)
  String? deviceId;

  @HiveField(15)
  bool isDeletionSynced;

  @HiveField(16)
  DateTime? lastSyncAt;

  @HiveField(17)
  int versionNumber;

  VoiceNoteModel({
    this.voiceNoteId,
    required this.voiceNoteTitle,
    required this.audioFilePath,
    required this.durationInSeconds,
    required this.fileSizeInBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.userId,
    this.isSynced = false,
    this.isDeleted = false,
    List<String>? tags,
    this.description,
    this.deletedAt,
    this.deletedBy,
    this.deviceId,
    this.isDeletionSynced = false,
    this.lastSyncAt,
    this.versionNumber = 1,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  // Helper method to format duration
  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Helper method to format file size
  String get formattedFileSize {
    if (fileSizeInBytes < 1024) {
      return '${fileSizeInBytes}B';
    } else if (fileSizeInBytes < 1024 * 1024) {
      return '${(fileSizeInBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSizeInBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  // Helper method to get file name from path
  String get fileName {
    return audioFilePath.split('/').last;
  }

  // Copy with method for updates
  VoiceNoteModel copyWith({
    String? voiceNoteId,
    String? voiceNoteTitle,
    String? audioFilePath,
    int? durationInSeconds,
    int? fileSizeInBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? isSynced,
    bool? isDeleted,
    List<String>? tags,
    String? description,
    DateTime? deletedAt,
    String? deletedBy,
    String? deviceId,
    bool? isDeletionSynced,
    DateTime? lastSyncAt,
    int? versionNumber,
  }) {
    return VoiceNoteModel(
      voiceNoteId: voiceNoteId ?? this.voiceNoteId,
      voiceNoteTitle: voiceNoteTitle ?? this.voiceNoteTitle,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      fileSizeInBytes: fileSizeInBytes ?? this.fileSizeInBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      deviceId: deviceId ?? this.deviceId,
      isDeletionSynced: isDeletionSynced ?? this.isDeletionSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      versionNumber: versionNumber ?? this.versionNumber,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'voiceNoteId': voiceNoteId,
      'voiceNoteTitle': voiceNoteTitle,
      'audioFilePath': audioFilePath,
      'durationInSeconds': durationInSeconds,
      'fileSizeInBytes': fileSizeInBytes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'tags': tags,
      'description': description,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'deviceId': deviceId,
      'isDeletionSynced': isDeletionSynced,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'versionNumber': versionNumber,
    };
  }

  // Factory constructor from Map (for Firestore)
  factory VoiceNoteModel.fromMap(Map<String, dynamic> data) {
    return VoiceNoteModel(
      voiceNoteId: data['voiceNoteId'],
      voiceNoteTitle: data['voiceNoteTitle'] ?? '',
      audioFilePath: data['audioFilePath'] ?? '',
      durationInSeconds: data['durationInSeconds'] ?? 0,
      fileSizeInBytes: data['fileSizeInBytes'] ?? 0,
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      userId: data['userId'] ?? '',
      isSynced: data['isSynced'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      description: data['description'],
      deletedAt:
          data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      deletedBy: data['deletedBy'],
      deviceId: data['deviceId'],
      isDeletionSynced: data['isDeletionSynced'] ?? false,
      lastSyncAt: data['lastSyncAt'] != null
          ? DateTime.parse(data['lastSyncAt'])
          : null,
      versionNumber: data['versionNumber'] ?? 1,
    );
  }
}
