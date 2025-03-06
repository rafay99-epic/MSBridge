import 'package:cloud_firestore/cloud_firestore.dart';

class NoteTakingModel {
  String? noteId;
  String noteContent;
  String noteTitle;

  NoteTakingModel({
    this.noteId,
    required this.noteContent,
    required this.noteTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'noteTitle': noteTitle,
      'noteContent': noteContent,
    };
  }

  factory NoteTakingModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NoteTakingModel(
      noteId: doc.id,
      noteTitle: data['noteTitle'] ?? '',
      noteContent: data['noteContent'] ?? '',
    );
  }

  factory NoteTakingModel.fromMap(Map<String, dynamic> data) {
    return NoteTakingModel(
      noteId: data['noteId'],
      noteTitle: data['noteTitle'] ?? '',
      noteContent: data['noteContent'] ?? '',
    );
  }
}
