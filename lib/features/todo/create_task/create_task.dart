import 'package:flutter/material.dart';
import 'package:msbridge/core/provider/todo_provider.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TaskEntryScreen extends StatefulWidget {
  const TaskEntryScreen({super.key});

  @override
  State<TaskEntryScreen> createState() => _TaskEntryScreenState();
}

class _TaskEntryScreenState extends State<TaskEntryScreen> {
  final taskController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDueDate;

  @override
  void dispose() {
    taskController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDueDate) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Add New Task',
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: taskController,
              style: TextStyle(color: theme.colorScheme.primary),
              decoration: InputDecoration(
                hintText: "Task Title",
                hintStyle: TextStyle(
                    color: theme.colorScheme.primary.withOpacity(0.5)),
                filled: true,
                fillColor: theme.colorScheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: theme.colorScheme.secondary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: theme.colorScheme.primary),
              decoration: InputDecoration(
                hintText: "Task Description (Optional)",
                hintStyle: TextStyle(
                    color: theme.colorScheme.primary.withOpacity(0.5)),
                filled: true,
                fillColor: theme.colorScheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: theme.colorScheme.secondary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDueDate == null
                        ? 'No due date selected'
                        : 'Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDueDate!)}',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => selectDate(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                  child: const Text('Select Due Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
              onPressed: () {
                if (taskController.text.isEmpty) {
                  CustomSnackBar.show(context, "Please enter the task title.");
                  return;
                }

                Provider.of<TodoProvider>(context, listen: false).addTask(
                  context,
                  taskController.text,
                  descriptionController.text,
                  selectedDueDate,
                );

                Navigator.pop(context);
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}
