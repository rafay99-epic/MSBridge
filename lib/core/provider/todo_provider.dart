// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/core/models/todo_model.dart';

class TodoProvider with ChangeNotifier {
  List<TodoItem> _tasks = [];
  List<TodoItem> _completedTasks = [];
  late SharedPreferences _prefs;
  bool _isLoading = false;
  String? _errorMessage;

  List<TodoItem> get tasks => _tasks;
  List<TodoItem> get completedTasks => _completedTasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadTasks();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to initialize: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to initialize: $e',
      );
      _errorMessage = "Failed to initialize: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(
    String title,
    String? description,
    DateTime? dueDate,
  ) async {
    _errorMessage = null;
    try {
      final now = DateTime.now();
      final newTask = TodoItem(
          title: title,
          description: description,
          dueDate: dueDate,
          createdAt: now);
      _tasks.add(newTask);
      await _saveTasks();
    } catch (e) {
      _errorMessage = "Failed to add task: ${e.toString()}";
      FlutterBugfender.sendCrash(
          'Failed to add task: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to add task: $e',
      );
      throw Exception("Failed to add task: ${e.toString()}");
    } finally {
      notifyListeners();
    }
  }

  Future<void> toggleTask(
    int index,
    bool isFromCompleteList,
  ) async {
    _errorMessage = null;
    try {
      if (isFromCompleteList) {
        if (index < 0 || index >= _completedTasks.length) {
          throw Exception("Invalid index for completed tasks list");
        }
        TodoItem task = _completedTasks[index];
        _completedTasks.removeAt(index);
        _tasks.add(task.copyWith(isCompleted: false));
      } else {
        if (index < 0 || index >= _tasks.length) {
          throw Exception("Invalid index for tasks list");
        }
        TodoItem task = _tasks[index];
        _tasks.removeAt(index);
        _completedTasks.add(task.copyWith(isCompleted: true));
      }
      await _saveTasks();
    } catch (e) {
      _errorMessage = "Failed to toggle task: ${e.toString()}";
      FlutterBugfender.sendCrash(
          'Failed to toggle task: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to toggle task: $e',
      );
      throw Exception("Failed to toggle task: ${e.toString()}");
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeTask(
    int index,
    bool isCompleted,
  ) async {
    _errorMessage = null;
    try {
      if (isCompleted) {
        if (index < 0 || index >= _completedTasks.length) {
          throw Exception("Invalid index for completed tasks list");
        }
        _completedTasks.removeAt(index);
      } else {
        _tasks.removeAt(index);
      }
      await _saveTasks();
    } catch (e) {
      if (index < 0 || index >= _tasks.length) {
        throw Exception("Invalid index for tasks list");
      }
      _errorMessage = "Failed to remove task: ${e.toString()}";
      FlutterBugfender.sendCrash(
          'Failed to remove task: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to remove task: $e',
      );
      throw Exception("Failed to remove task: ${e.toString()}");
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadTasks() async {
    _errorMessage = null;
    try {
      final tasksJson = _prefs.getStringList('tasks') ?? [];
      final completedTasksJson = _prefs.getStringList('completedTasks') ?? [];

      _tasks =
          tasksJson.map((json) => TodoItem.fromJson(jsonDecode(json))).toList();
      _completedTasks = completedTasksJson
          .map((json) => TodoItem.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      _errorMessage = "Failed to load tasks: ${e.toString()}";
      FlutterBugfender.sendCrash(
          'Failed to load tasks: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to load tasks: $e',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    _errorMessage = null;
    try {
      final tasksJson =
          _tasks.map((task) => jsonEncode(task.toJson())).toList();
      final completedTasksJson =
          _completedTasks.map((task) => jsonEncode(task.toJson())).toList();
      await _prefs.setStringList('tasks', tasksJson);
      await _prefs.setStringList('completedTasks', completedTasksJson);
    } catch (e) {
      _errorMessage = "Failed to save tasks: ${e.toString()}";
      FlutterBugfender.sendCrash(
          'Failed to save tasks: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to save tasks: $e',
      );
    } finally {
      notifyListeners();
    }
  }
}
