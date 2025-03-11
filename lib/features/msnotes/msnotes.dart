import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/msnotes/lectures_screen.dart';
import 'package:msbridge/utils/empty_ui.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';

class Msnotes extends StatefulWidget {
  const Msnotes({super.key});

  @override
  State<Msnotes> createState() => _MSNotesScreenState();
}

class _MSNotesScreenState extends State<Msnotes> {
  List<String> subjects = [];
  final InternetHelper _internetHelper = InternetHelper();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _internetHelper.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    var box = Hive.box<MSNote>('notesBox');
    List<MSNote> notes = box.values.toList();
    Set<String> uniqueSubjects = notes.map((note) => note.subject).toSet();
    setState(() {
      subjects = uniqueSubjects.toList();
    });
  }

  Future<void> _refreshData() async {
    if (_internetHelper.connectivitySubject.value) {
      await Future.delayed(const Duration(seconds: 2));
      _loadSubjects();
      CustomSnackBar.show(
        context,
        "Notes updated from the server!",
      );
    } else {
      CustomSnackBar.show(
        context,
        "No Internet Connection, Please connect and try again",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(
        title: "MS Notes",
        backbutton: false,
      ),
      body: RefreshIndicator(
        backgroundColor: theme.colorScheme.secondary,
        color: theme.colorScheme.surface,
        onRefresh: _refreshData,
        child: subjects.isEmpty
            ? const EmptyNotesMessage(
                message: 'Sorry Subject not found',
                description: 'Pull down to refresh',
              )
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
      ),
    );
  }
}
