import 'package:flutter/material.dart';
import 'package:msbridge/core/repo/todo_repo.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
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
  final TodoRepository _todoRepository = TodoRepository();

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
      appBar: const CustomAppBar(
        title: 'Add New Task',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Task Title',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: taskController,
              style: TextStyle(color: theme.colorScheme.primary),
              decoration: InputDecoration(
                hintText: "Enter task title",
                hintStyle: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: theme.colorScheme.secondary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Description',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: theme.colorScheme.primary),
              decoration: InputDecoration(
                hintText: "Optional description",
                hintStyle: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: theme.colorScheme.secondary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),
            Text(
              'Due Date',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
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
                      selectedDueDate == null
                          ? 'No due date selected'
                          : DateFormat('yyyy-MM-dd').format(selectedDueDate!),
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Select Date'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              onPressed: () async {
                if (taskController.text.isEmpty) {
                  CustomSnackBar.show(context, "Please enter the task title.");
                  return;
                }

                try {
                  await _todoRepository.addTask(
                    context,
                    taskController.text,
                    descriptionController.text,
                    selectedDueDate,
                  );
                  CustomSnackBar.show(context, "Task added successfully!",
                      isSuccess: true);
                  Navigator.pop(context);
                } catch (e) {
                  CustomSnackBar.show(context, e.toString());
                }
              },
              child: Text(
                'Add Task',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
