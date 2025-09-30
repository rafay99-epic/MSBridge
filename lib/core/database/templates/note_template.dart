// Package imports:
import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class NoteTemplate extends HiveObject {
  @HiveField(0)
  String templateId;

  @HiveField(1)
  String title;

  // Stored as Quill Delta JSON string, same as notes
  @HiveField(2)
  String contentJson;

  @HiveField(3)
  List<String> tags;

  @HiveField(4)
  String? userId;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isBuiltIn;

  NoteTemplate({
    required this.templateId,
    required this.title,
    required this.contentJson,
    List<String>? tags,
    this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isBuiltIn = false,
  })  : tags = List<String>.from(tags ?? const []),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

// Manual adapter to avoid depending on build_runner immediately
class NoteTemplateAdapter extends TypeAdapter<NoteTemplate> {
  @override
  final int typeId = 3;

  @override
  NoteTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return NoteTemplate(
      templateId: fields[0] as String,
      title: fields[1] as String,
      contentJson: fields[2] as String,
      tags: (fields[3] as List?)?.cast<String>() ?? const [],
      userId: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
      isBuiltIn: (fields[7] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, NoteTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.templateId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.contentJson)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.isBuiltIn);
  }
}
