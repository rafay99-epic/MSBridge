import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/core/provider/todo_provider.dart';
import 'package:msbridge/core/repo/todo_repo.dart';
import 'package:msbridge/features/todo/create_task/create_task.dart';
import 'package:msbridge/utils/empty_ui.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';

class ToDO extends StatefulWidget {
  const ToDO({super.key});

  @override
  State<ToDO> createState() => _ToDOState();
}

class _ToDOState extends State<ToDO> {
  final TodoRepository _todoRepository = TodoRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const CustomAppBar(
          showTitle: true,
          title: "To-Do",
          showBackButton: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TabBar(
                dividerColor: Colors.transparent,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor:
                    theme.colorScheme.primary.withOpacity(0.6),
                indicatorColor: theme.colorScheme.secondary,
                indicatorWeight: 3.0,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: "Tasks"),
                  Tab(text: "Completed"),
                ],
              ),
            ),
            Expanded(
              child: Consumer<TodoProvider>(
                builder: (context, todoProvider, _) {
                  return TabBarView(
                    children: [
                      _buildTaskList(context, todoProvider.tasks, false, theme,
                          _todoRepository),
                      _buildTaskList(context, todoProvider.completedTasks, true,
                          theme, _todoRepository),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.surface,
          onPressed: () async {
            await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const TaskEntryScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    List tasks,
    bool isCompleted,
    ThemeData theme,
    TodoRepository todoRepository,
  ) {
    if (tasks.isEmpty) {
      return const Center(
        child: EmptyNotesMessage(
          message: 'Sorry No Task not found',
          description: 'Click on the + button to add a new task',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          margin: const EdgeInsets.only(bottom: 15),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              task.title,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      task.description!,
                      style: TextStyle(
                          color: theme.colorScheme.primary.withOpacity(0.8),
                          fontSize: 14),
                    ),
                  ),
                if (task.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Due: ${DateFormat('yyyy-MM-dd').format(task.dueDate!)}',
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Created: ${DateFormat('yyyy-MM-dd').format(task.createdAt)}',
                    style: TextStyle(
                        color: theme.colorScheme.primary.withOpacity(0.6),
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isCompleted ? LineIcons.undo : LineIcons.checkCircle,
                    color: theme.colorScheme.secondary,
                  ),
                  onPressed: () async {
                    try {
                      await todoRepository.toggleTask(
                          context, index, isCompleted);
                    } catch (e) {
                      FlutterBugfender.sendCrash('Failed to toggle task.',
                          StackTrace.current.toString());
                      FlutterBugfender.error('Failed to toggle task.');
                      CustomSnackBar.show(context, e.toString());
                    }
                  },
                ),
                IconButton(
                  icon: Icon(LineIcons.trash,
                      color: Theme.of(context).colorScheme.primary),
                  onPressed: () async {
                    try {
                      await todoRepository.removeTask(
                          context, index, isCompleted);
                    } catch (e) {
                      FlutterBugfender.sendCrash('Failed to remove task.',
                          StackTrace.current.toString());
                      FlutterBugfender.error('Failed to remove task.');
                      CustomSnackBar.show(context, e.toString());
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
