import 'dart:convert';
import 'package:msbridge/core/models/todo_model.dart';
import 'package:msbridge/widgets/snakbar.dart';
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

  Future<void> initialize(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadTasks(context);
      CustomSnackBar.show(context, "Tasks loaded successfully!",
          isSuccess: true);
    } catch (e) {
      _errorMessage = "Failed to initialize: ${e.toString()}";
      CustomSnackBar.show(context, _errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(BuildContext context, String title, String? description,
      DateTime? dueDate) async {
    _errorMessage = null;
    try {
      final now = DateTime.now();
      final newTask = TodoItem(
          title: title,
          description: description,
          dueDate: dueDate,
          createdAt: now);
      _tasks.add(newTask);
      await _saveTasks(context);
      CustomSnackBar.show(context, "Task added successfully!", isSuccess: true);
    } catch (e) {
      _errorMessage = "Failed to add task: ${e.toString()}";
      CustomSnackBar.show(context, _errorMessage!);
    } finally {
      notifyListeners();
    }
  }

  Future<void> toggleTask(
      BuildContext context, int index, bool isFromCompleteList) async {
    _errorMessage = null;
    String message = isFromCompleteList ? "Task restored!" : "Task completed!";
    try {
      if (isFromCompleteList) {
        TodoItem task = _completedTasks[index];
        _completedTasks.removeAt(index);
        _tasks.add(task.copyWith(isCompleted: false));
      } else {
        TodoItem task = _tasks[index];
        _tasks.removeAt(index);
        _completedTasks.add(task.copyWith(isCompleted: true));
      }
      await _saveTasks(context);
      CustomSnackBar.show(context, message, isSuccess: true);
    } catch (e) {
      _errorMessage = "Failed to toggle task: ${e.toString()}";
      CustomSnackBar.show(context, _errorMessage!);
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeTask(
      BuildContext context, int index, bool isCompleted) async {
    _errorMessage = null;
    String message =
        isCompleted ? "Task permanently deleted!" : "Task removed permanently!";
    try {
      if (isCompleted) {
        _completedTasks.removeAt(index);
      } else {
        _tasks.removeAt(index);
      }
      await _saveTasks(context);
      CustomSnackBar.show(context, message, isSuccess: true);
    } catch (e) {
      _errorMessage = "Failed to remove task: ${e.toString()}";
      CustomSnackBar.show(context, _errorMessage!);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadTasks(BuildContext context) async {
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
      CustomSnackBar.show(context, _errorMessage!);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveTasks(BuildContext context) async {
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
      CustomSnackBar.show(context, _errorMessage!);
    } finally {
      notifyListeners();
    }
  }
}
