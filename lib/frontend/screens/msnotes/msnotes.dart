import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/backend/hive/note_reading/notes_model.dart';
import 'package:msbridge/frontend/screens/msnotes/lectures_screen.dart';
import 'package:page_transition/page_transition.dart';

class Msnotes extends StatefulWidget {
  const Msnotes({super.key});

  @override
  State<Msnotes> createState() => _MSNotesScreenState();
}

class _MSNotesScreenState extends State<Msnotes> {
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() async {
    var box = Hive.box<MSNote>('notesBox');
    List<MSNote> notes = box.values.toList();
    Set<String> uniqueSubjects = notes.map((note) => note.subject).toSet();
    setState(() {
      subjects = uniqueSubjects.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("MS Notes"),
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: subjects.isEmpty
          ? const Center(child: Text("No Subjects Available"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                return Card(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.secondary,
                      width: 3,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    hoverColor: theme.colorScheme.secondary.withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    title: Text(
                      subjects[index],
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    trailing: Icon(
                      LineIcons.angleRight,
                      color: theme.colorScheme.secondary,
                    ),
                    onTap: () {
                      debugPrint("Subject Selected: ${subjects[index]}");
                      var box = Hive.box<MSNote>('notesBox');
                      List<MSNote> subjectLectures = box.values
                          .where((note) => note.subject == subjects[index])
                          .toList()
                        ..sort((a, b) =>
                            a.lectureNumber.compareTo(b.lectureNumber));
                      Navigator.push(
                        context,
                        PageTransition(
                          child: LecturesScreen(
                            subject: subjects[index],
                            lectures: subjectLectures,
                          ),
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
