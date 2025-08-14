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

  NoteTakingModel({
    this.noteId,
    required this.noteTitle,
    required this.noteContent,
    this.isSynced = false,
    this.isDeleted = false,
    DateTime? updatedAt,
    required this.userId,
    List<String>? tags,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? const [];

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
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
