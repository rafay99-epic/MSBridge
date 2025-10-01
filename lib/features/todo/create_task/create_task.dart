// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:msbridge/core/repo/todo_repo.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';

class TaskEntryScreen extends StatefulWidget {
  const TaskEntryScreen({super.key});

  @override
  State<TaskEntryScreen> createState() => _TaskEntryScreenState();
}

class _TaskEntryScreenState extends State<TaskEntryScreen> {
  final _taskController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  final TodoRepository _todoRepository = TodoRepository();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _taskController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const CustomAppBar(
          title: 'Add New Task',
          showBackButton: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildTextField(
                  controller: _taskController,
                  label: 'Task Title',
                  hint: 'Enter task title',
                  validator: (value) =>
                      value!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Optional description',
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                _buildDatePicker(context, theme),
                const SizedBox(height: 30),
                _buildSubmitButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: theme.colorScheme.primary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.secondary),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.secondary),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDueDate == null
                        ? 'No due date selected'
                        : DateFormat('yyyy-MM-dd').format(_selectedDueDate!),
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () async {
        if (!_formKey.currentState!.validate()) return;

        try {
          await _todoRepository.addTask(
            context,
            _taskController.text,
            _descriptionController.text,
            _selectedDueDate,
          );
          if (context.mounted) {
            CustomSnackBar.show(context, 'Task added successfully!',
                isSuccess: true);
          }
          if (context.mounted) {
            Navigator.pop(context);
          }
        } catch (e) {
          FlutterBugfender.sendCrash(
              'Failed to add task.', StackTrace.current.toString());
          FlutterBugfender.error('Failed to add task.');
          if (context.mounted) {
            CustomSnackBar.show(context, e.toString(), isSuccess: false);
          }
          if (context.mounted) {
            CustomSnackBar.show(context, e.toString(), isSuccess: false);
          }
        }
      },
      child: Text('Add Task',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}
