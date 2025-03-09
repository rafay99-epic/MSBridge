import 'package:cloud_firestore/cloud_firestore.dart';

class NoteTakingModel {
  String? noteId;
  String noteContent;
  String noteTitle;
  bool isSynced;
  bool isDeleted;
  DateTime updatedAt;
  String? userId;

  NoteTakingModel({
    this.noteId,
    required this.noteContent,
    required this.noteTitle,
    this.isSynced = false,
    this.isDeleted = false,
    DateTime? updatedAt,
    this.userId,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'noteTitle': noteTitle,
      'noteContent': noteContent,
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory NoteTakingModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    DateTime parsedDate;

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    try {
      parsedDate = DateTime.parse(data['updatedAt'] ?? '');
    } catch (e) {
      parsedDate = DateTime.now();
    }
    return NoteTakingModel(
      noteId: doc.id,
      noteTitle: data['noteTitle'] ?? '',
      noteContent: data['noteContent'] ?? '',
      isSynced: data['isSynced'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      updatedAt: parsedDate,
      userId: data['userId'] ?? '',
    );
  }

  factory NoteTakingModel.fromMap(Map<String, dynamic> data) {
    return NoteTakingModel(
      noteId: data['noteId'],
      noteTitle: data['noteTitle'] ?? '',
      noteContent: data['noteContent'] ?? '',
      isSynced: data['isSynced'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      updatedAt:
          DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      userId: data['userId'] ?? '',
    );
  }
}
