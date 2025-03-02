import 'package:hive/hive.dart';
part 'notes_model.g.dart';

@HiveType(typeId: 0) // Unique ID for this model
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
  String body;

  MSNote({
    required this.id,
    required this.lectureTitle,
    required this.lectureDescription,
    required this.pubDate,
    required this.lectureDraft,
    required this.lectureNumber,
    required this.subject,
    required this.body,
  });

  factory MSNote.fromJson(Map<String, dynamic> json) {
    return MSNote(
      id: json['id'],
      lectureTitle: json['data']['lecture_title'],
      lectureDescription: json['data']['lecture_description'],
      pubDate: json['data']['pubDate'],
      lectureDraft: json['data']['lecture_draft'],
      lectureNumber: json['data']['lectureNumber'],
      subject: json['data']['subject'],
      body: json['body'],
    );
  }
}
