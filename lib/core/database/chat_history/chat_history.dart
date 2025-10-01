// Package imports:
import 'package:hive/hive.dart';

part 'chat_history.g.dart';

@HiveType(typeId: 10)
class ChatHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<ChatHistoryMessage> messages;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime lastUpdated;

  @HiveField(5)
  final bool includePersonal;

  @HiveField(6)
  final bool includeMsNotes;

  @HiveField(7)
  final String modelName;

  ChatHistory({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.lastUpdated,
    required this.includePersonal,
    required this.includeMsNotes,
    required this.modelName,
  });

  ChatHistory copyWith({
    String? id,
    String? title,
    List<ChatHistoryMessage>? messages,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? includePersonal,
    bool? includeMsNotes,
    String? modelName,
  }) {
    return ChatHistory(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      includePersonal: includePersonal ?? this.includePersonal,
      includeMsNotes: includeMsNotes ?? this.includeMsNotes,
      modelName: modelName ?? this.modelName,
    );
  }
}

@HiveType(typeId: 11)
class ChatHistoryMessage {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final bool fromUser;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final bool isError;

  @HiveField(4)
  final String? errorDetails;

  @HiveField(5)
  final List<String> imageUrls;

  ChatHistoryMessage({
    required this.text,
    required this.fromUser,
    required this.timestamp,
    this.isError = false,
    this.errorDetails,
    List<String>? imageUrls,
  }) : imageUrls = imageUrls ?? const [];
}
