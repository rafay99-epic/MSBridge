// Package imports:
import 'package:hive/hive.dart';

part 'notes_model.g.dart';

@HiveType(typeId: 0)
class MSNote {
  @HiveField(0)
  String id;

  @HiveField(1)
  String lectureTitle;

  @HiveField(2)
  String lectureDescription;

  @HiveField(3)
  String pubDate;

  @HiveField(4)
  bool lectureDraft;

  @HiveField(5)
  String lectureNumber;

  @HiveField(6)
  String subject;

  @HiveField(7)
  String? body;

  MSNote({
    required this.id,
    required this.lectureTitle,
    required this.lectureDescription,
    required this.pubDate,
    required this.lectureDraft,
    required this.lectureNumber,
    required this.subject,
    this.body,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lectureTitle': lectureTitle,
      'lectureDescription': lectureDescription,
      'pubDate': pubDate,
      'lectureDraft': lectureDraft,
      'lectureNumber': lectureNumber,
      'subject': subject,
      'body': body,
    };
  }

  factory MSNote.fromJson(Map<String, dynamic> json) {
    // Add a null check for the 'data' field
    final data = json['data'] as Map<String, dynamic>?;

    return MSNote(
      // Safely access the 'id', convert it to a string, and use a default value
      id: (json['id']?.toString()) ?? '0', // Or some other suitable default

      // Safely access nested values using the null-aware operator and provide defaults
      lectureTitle: data?['lecture_title'] ?? '',
      lectureDescription: data?['lecture_description'] ?? '',
      pubDate: data?['pubDate'] ?? '',
      lectureDraft: data?['lectureDraft'] ?? false,
      lectureNumber: (data?['lectureNumber']?.toString()) ?? '0',
      subject: data?['subject'] ?? '',
      body: data?['body'],
    );
  }
}
