import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

class _MSNotesScreenState extends State<Msnotes>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final InternetHelper _internetHelper = InternetHelper();
  Box<MSNote>? _notesBox;
  ValueListenable<Box<MSNote>>? _notesBoxListenable;
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    _openHiveBox();
  }

  @override
  void dispose() {
    _internetHelper.dispose();
    _notesBox?.close();
    super.dispose();
  }

  Future<void> _openHiveBox() async {
    _notesBox = await Hive.openBox<MSNote>('notesBox');
    _notesBoxListenable = _notesBox!.listenable();
    setState(() {});
  }

  List<String> _getSubjects(Box<MSNote> box) {
    List<MSNote> notes = box.values.toList();
    Set<String> uniqueSubjects = notes.map((note) => note.subject).toSet();
    return uniqueSubjects.toList();
  }

  Future<void> _refreshData() async {
    if (_internetHelper.connectivitySubject.value) {
      await Future.delayed(const Duration(seconds: 2));
      if (_notesBox != null) {
        setState(() {
          subjects = _getSubjects(_notesBox!);
        });
      }

      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Notes updated from the server!",
        );
      }
    } else {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "No Internet Connection, Please connect and try again",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(
        title: "MS Notes",
        backbutton: false,
      ),
      body: _notesBoxListenable == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              backgroundColor: theme.colorScheme.secondary,
              color: theme.colorScheme.surface,
              onRefresh: _refreshData,
              child: ValueListenableBuilder<Box<MSNote>>(
                valueListenable: _notesBoxListenable!,
                builder: (context, box, _) {
                  final subjects = _getSubjects(box);
                  return LayoutBuilder(
                    builder: (BuildContext context,
                        BoxConstraints viewportConstraints) {
                      return subjects.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: viewportConstraints.maxHeight,
                                ),
                                child: const EmptyNotesMessage(
                                  message: 'Sorry Subject not found',
                                  description: 'Pull down to refresh',
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
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
                                    hoverColor: theme.colorScheme.secondary
                                        .withOpacity(0.1),
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
                                      debugPrint(
                                          "Subject Selected: ${subjects[index]}");
                                      var box = Hive.box<MSNote>('notesBox');
                                      List<MSNote> subjectLectures = box.values
                                          .where((note) =>
                                              note.subject == subjects[index])
                                          .toList()
                                        ..sort((a, b) => a.lectureNumber
                                            .compareTo(b.lectureNumber));
                                      Navigator.push(
                                        context,
                                        PageTransition(
                                          child: LecturesScreen(
                                            subject: subjects[index],
                                            lectures: subjectLectures,
                                          ),
                                          type: PageTransitionType.rightToLeft,
                                          duration:
                                              const Duration(milliseconds: 300),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                    },
                  );
                },
              ),
            ),
    );
  }
}
