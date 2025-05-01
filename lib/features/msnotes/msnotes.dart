import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/api/ms_notes_api.dart';
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
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _openHiveBox().then((_) {
      _fetchNotesFromServer(showSuccessSnackbar: false);
    });
  }

  @override
  void dispose() {
    _internetHelper.dispose();
    _notesBox?.close();
    super.dispose();
  }

  Future<void> _openHiveBox() async {
    try {
      _notesBox = await Hive.openBox<MSNote>('notesBox');
      _notesBoxListenable = _notesBox!.listenable();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error opening Hive box: $e");
      if (mounted) {
        CustomSnackBar.show(context, "Error accessing local notes storage.");
      }
    }
  }

  Future<void> _fetchNotesFromServer({bool showSuccessSnackbar = true}) async {
    if (_isFetching) return;

    final isConnected = _internetHelper.connectivitySubject.valueOrNull;

    if (isConnected != true) {
      if (showSuccessSnackbar && mounted) {
        final message = isConnected == false
            ? "No Internet Connection. Displaying cached notes."
            : "Checking connection... Displaying cached notes.";
        CustomSnackBar.show(context, message);
      } else if (isConnected == false) {
        debugPrint("No internet connection. Skipping server fetch.");
      } else {
        debugPrint("Internet status unknown yet. Skipping server fetch.");
      }
      return;
    }

    setState(() {
      _isFetching = true;
    });

    try {
      await ApiService.fetchAndSaveNotes();
      if (showSuccessSnackbar && mounted) {
        CustomSnackBar.show(
          context,
          "Notes updated from the server!",
        );
      }
    } catch (e) {
      debugPrint("Error fetching/saving notes: $e");
      if (mounted) {
        if (!_internetHelper.connectivitySubject.valueOrNull!) {
          CustomSnackBar.show(context, "Fetch failed: Lost connection.");
        } else {
          CustomSnackBar.show(
            context,
            "Error updating notes: $e",
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  List<String> _getSubjects(Box<MSNote> box) {
    final uniqueSubjects = box.values.map((note) => note.subject).toSet();
    final sortedSubjects = uniqueSubjects.toList()..sort();
    return sortedSubjects;
  }

  Future<void> _refreshData() async {
    await _fetchNotesFromServer(showSuccessSnackbar: true);
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
                                  message: 'No subjects found',
                                  description:
                                      'Pull down to refresh from server',
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: subjects.length,
                              itemBuilder: (context, index) {
                                final subject = subjects[index];
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
                                      subject,
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
                                      debugPrint("Subject Selected: $subject");
                                      List<MSNote> subjectLectures = box.values
                                          .where(
                                              (note) => note.subject == subject)
                                          .toList()
                                        ..sort((a, b) => a.lectureNumber
                                            .compareTo(b.lectureNumber));

                                      Navigator.push(
                                        context,
                                        PageTransition(
                                          child: LecturesScreen(
                                            subject: subject,
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
