import 'dart:convert';
import 'package:msbridge/core/models/todo_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

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
    } finally {
      notifyListeners();
    }
  }
}
