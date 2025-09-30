// Package imports:
import 'package:hive/hive.dart';

part 'note_version.g.dart';

@HiveType(typeId: 2)
class NoteVersion extends HiveObject {
  @HiveField(0)
  String? versionId;

  @HiveField(1)
  String noteId;

  @HiveField(2)
  String noteTitle;

  @HiveField(3)
  String noteContent;

  @HiveField(4)
  List<String> tags;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String userId;

  @HiveField(7)
  String changeDescription;

  @HiveField(8)
  int versionNumber;

  @HiveField(9)
  List<String> changes; // What changed in this version

  @HiveField(10)
  String previousVersionId; // Reference to previous version

  NoteVersion({
    this.versionId,
    required this.noteId,
    required this.noteTitle,
    required this.noteContent,
    required this.tags,
    required this.createdAt,
    required this.userId,
    this.changeDescription = '',
    required this.versionNumber,
    this.changes = const [],
    this.previousVersionId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'versionId': versionId,
      'noteId': noteId,
      'noteTitle': noteTitle,
      'noteContent': noteContent,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'changeDescription': changeDescription,
      'versionNumber': versionNumber,
      'changes': changes,
      'previousVersionId': previousVersionId,
    };
  }

  factory NoteVersion.fromMap(Map<String, dynamic> data) {
    return NoteVersion(
      versionId: data['versionId'],
      noteId: data['noteId'],
      noteTitle: data['noteTitle'],
      noteContent: data['noteContent'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: DateTime.parse(data['createdAt']),
      userId: data['userId'],
      changeDescription: data['changeDescription'] ?? '',
      versionNumber: data['versionNumber'] ?? 1,
      changes: List<String>.from(data['changes'] ?? []),
      previousVersionId: data['previousVersionId'] ?? '',
    );
  }

  NoteVersion copyWith({
    String? versionId,
    String? noteId,
    String? noteTitle,
    String? noteContent,
    List<String>? tags,
    DateTime? createdAt,
    String? userId,
    String? changeDescription,
    int? versionNumber,
    List<String>? changes,
    String? previousVersionId,
  }) {
    return NoteVersion(
      versionId: versionId ?? this.versionId,
      noteId: noteId ?? this.noteId,
      noteTitle: noteTitle ?? this.noteTitle,
      noteContent: noteContent ?? this.noteContent,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      changeDescription: changeDescription ?? this.changeDescription,
      versionNumber: versionNumber ?? this.versionNumber,
      changes: changes ?? this.changes,
      previousVersionId: previousVersionId ?? this.previousVersionId,
    );
  }

  /// Create a new version from this restored version
  NoteVersion createRestoredVersion({
    required String newNoteId,
    required String userId,
    required int newVersionNumber,
  }) {
    return NoteVersion(
      versionId: null, // Will be generated
      noteId: newNoteId,
      noteTitle: noteTitle,
      noteContent: noteContent,
      tags: tags,
      createdAt: DateTime.now(),
      userId: userId,
      changeDescription: 'Restored from version $versionNumber',
      versionNumber: newVersionNumber,
      changes: ['Restored from version $versionNumber'],
      previousVersionId: '', // This will be the current version
    );
  }
}
