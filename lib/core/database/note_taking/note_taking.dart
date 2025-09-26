import 'package:hive/hive.dart';

part 'note_taking.g.dart';

@HiveType(typeId: 1)
class NoteTakingModel extends HiveObject {
  @HiveField(0)
  String? noteId;

  @HiveField(1)
  String noteTitle;

  @HiveField(2)
  String noteContent;

  @HiveField(3)
  bool isSynced;

  @HiveField(4)
  bool isDeleted;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  String userId;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  int versionNumber;

  @HiveField(9)
  DateTime createdAt;

  // New fields for deletion sync
  @HiveField(10)
  DateTime? deletedAt;

  @HiveField(11)
  String? deletedBy;

  @HiveField(12)
  String? deviceId;

  @HiveField(13)
  bool isDeletionSynced;

  @HiveField(14)
  DateTime? lastSyncAt;

  @HiveField(15)
  List<String> outgoingLinkIds;

  NoteTakingModel({
    this.noteId,
    required this.noteTitle,
    required this.noteContent,
    this.isSynced = false,
    this.isDeleted = false,
    DateTime? updatedAt,
    required this.userId,
    List<String>? tags,
    this.versionNumber = 1,
    DateTime? createdAt,
    this.deletedAt,
    this.deletedBy,
    this.deviceId,
    this.isDeletionSynced = false,
    this.lastSyncAt,
    List<String>? outgoingLinkIds,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? const [],
        createdAt = createdAt ?? DateTime.now(),
        outgoingLinkIds = outgoingLinkIds ?? const [];

  /// Mark note as deleted with proper tracking
  void markAsDeleted(String deviceId, String userId) {
    isDeleted = true;
    deletedAt = DateTime.now();
    deletedBy = userId;
    this.deviceId = deviceId;
    isDeletionSynced = false;
    updatedAt = DateTime.now();
  }

  /// Mark note as restored
  void restore() {
    isDeleted = false;
    deletedAt = null;
    deletedBy = null;
    deviceId = null;
    isDeletionSynced = false;
    updatedAt = DateTime.now();
  }

  /// Check if note should be synced (not deleted or deletion already synced)
  bool get shouldSync {
    if (!isDeleted) return !isSynced;
    return !isDeletionSynced;
  }

  /// Check if note is permanently deleted (older than cleanup threshold)
  bool get isPermanentlyDeleted {
    if (deletedAt == null) return false;
    final cleanupThreshold = DateTime.now().subtract(const Duration(days: 30));
    return deletedAt!.isBefore(cleanupThreshold);
  }

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'noteTitle': noteTitle,
      'noteContent': noteContent,
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'tags': tags,
      'versionNumber': versionNumber,
      'createdAt': createdAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'deviceId': deviceId,
      'isDeletionSynced': isDeletionSynced,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'outgoingLinkIds': outgoingLinkIds,
    };
  }

  factory NoteTakingModel.fromMap(Map<String, dynamic> data) {
    return NoteTakingModel(
      noteId: data['noteId'],
      noteTitle: data['noteTitle'] ?? '',
      noteContent: data['noteContent'] ?? '',
      isSynced: data['isSynced'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      userId: data['userId'] ?? '',
      updatedAt:
          DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      versionNumber: data['versionNumber'] ?? 1,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      deletedAt:
          data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      deletedBy: data['deletedBy'],
      deviceId: data['deviceId'],
      isDeletionSynced: data['isDeletionSynced'] ?? false,
      lastSyncAt: data['lastSyncAt'] != null
          ? DateTime.parse(data['lastSyncAt'])
          : null,
      outgoingLinkIds: (data['outgoingLinkIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  NoteTakingModel copyWith({
    String? noteId,
    String? noteTitle,
    String? noteContent,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
    String? userId,
    List<String>? tags,
    int? versionNumber,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
    String? deviceId,
    bool? isDeletionSynced,
    DateTime? lastSyncAt,
    List<String>? outgoingLinkIds,
  }) {
    return NoteTakingModel(
      noteId: noteId ?? this.noteId,
      noteTitle: noteTitle ?? this.noteTitle,
      noteContent: noteContent ?? this.noteContent,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
      versionNumber: versionNumber ?? this.versionNumber,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      deviceId: deviceId ?? this.deviceId,
      isDeletionSynced: isDeletionSynced ?? this.isDeletionSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      outgoingLinkIds: outgoingLinkIds ?? this.outgoingLinkIds,
    );
  }
}
