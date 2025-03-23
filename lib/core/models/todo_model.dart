class TodoItem {
  String title;
  String? description;
  DateTime? dueDate;
  bool isCompleted;
  DateTime createdAt;

  TodoItem(
      {required this.title,
      this.description,
      this.dueDate,
      this.isCompleted = false,
      required this.createdAt});

  TodoItem copyWith(
      {String? title,
      String? description,
      DateTime? dueDate,
      bool? isCompleted,
      DateTime? createdAt}) {
    return TodoItem(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    if (json['title'] == null || json['createdAt'] == null) {
      throw FormatException('Missing required fields in TodoItem JSON');
    }
    return TodoItem(
      title: json['title'],
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
