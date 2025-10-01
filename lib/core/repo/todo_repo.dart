// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/provider/todo_provider.dart';

class TodoRepository {
  Future<void> addTask(
    BuildContext context,
    String title,
    String? description,
    DateTime? dueDate,
  ) async {
    try {
      await Provider.of<TodoProvider>(context, listen: false).addTask(
        title,
        description,
        dueDate,
      );
    } catch (e) {
      throw Exception("Failed to add task: ${e.toString()}");
    }
  }

  Future<void> toggleTask(
    BuildContext context,
    int index,
    bool isFromCompleteList,
  ) async {
    try {
      await Provider.of<TodoProvider>(context, listen: false).toggleTask(
        index,
        isFromCompleteList,
      );
    } catch (e) {
      throw Exception("Failed to toggle task: ${e.toString()}");
    }
  }

  Future<void> removeTask(
    BuildContext context,
    int index,
    bool isCompleted,
  ) async {
    try {
      await Provider.of<TodoProvider>(context, listen: false).removeTask(
        index,
        isCompleted,
      );
    } catch (e) {
      throw Exception("Failed to remove task: ${e.toString()}");
    }
  }
}
