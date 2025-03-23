import 'package:flutter/material.dart';
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
            TabBar(
              dividerColor: Colors.transparent,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.primary.withOpacity(0.6),
              indicatorColor: theme.colorScheme.secondary,
              tabs: const [
                Tab(text: "Tasks"),
                Tab(text: "Completed"),
              ],
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
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              task.title,
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty)
                  Text(
                    task.description!,
                    style: TextStyle(
                        color: theme.colorScheme.primary.withOpacity(0.8)),
                  ),
                if (task.dueDate != null)
                  Text(
                    'Due: ${DateFormat('yyyy-MM-dd').format(task.dueDate!)}',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                Text(
                  'Created: ${DateFormat('yyyy-MM-dd').format(task.createdAt)}',
                  style: TextStyle(
                      color: theme.colorScheme.primary.withOpacity(0.5)),
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
