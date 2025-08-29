import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/api/ms_notes_api.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/msnotes/lectures_screen.dart';
import 'package:msbridge/features/msnotes/widgets/loading_state_widget.dart';
import 'package:msbridge/features/msnotes/widgets/empty_state_widget.dart';
import 'package:msbridge/features/msnotes/widgets/section_header_widget.dart';
import 'package:msbridge/features/msnotes/widgets/subject_card_widget.dart';
import 'package:msbridge/features/notes_taking/search/advanced_search_screen.dart';
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

  void fetchNotes() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Check if connectivity subject has a value before accessing it
        if (!_internetHelper.connectivitySubject.hasValue) {
          FlutterBugfender.log("Connectivity subject not initialized yet");
          return;
        }

        final connected = _internetHelper.connectivitySubject.value;
        if (connected) {
          await _refreshData();
        } else {
          if (mounted) {
            FlutterBugfender.log(
                "No Internet Connection, Please connect and try again");
            CustomSnackBar.show(
              context,
              "No Internet Connection, Please connect and try again",
              isSuccess: false,
            );
          }
        }
      } catch (e) {
        FlutterBugfender.log("Error fetching notes: $e");
        FlutterBugfender.error(e.toString());
        if (mounted) {
          CustomSnackBar.show(
            context,
            "Error fetching notes: $e",
            isSuccess: false,
          );
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchNotes();
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
    setState(() {
      FlutterBugfender.log("Hive box opened");
    });
  }

  List<String> _getSubjects(Box<MSNote> box) {
    List<MSNote> notes = box.values.toList();
    Set<String> uniqueSubjects = notes.map((note) => note.subject).toSet();
    return uniqueSubjects.toList();
  }

  Future<void> _refreshData() async {
    // Check if connectivity subject has a value before accessing it
    if (!_internetHelper.connectivitySubject.hasValue) {
      FlutterBugfender.log(
          "Connectivity subject not initialized yet in refresh");
      return;
    }

    if (_internetHelper.connectivitySubject.value) {
      await ApiService.fetchAndSaveNotes();
      await Future.delayed(const Duration(seconds: 2));
      if (_notesBox != null) {
        setState(() {
          subjects = _getSubjects(_notesBox!);
        });
      }

      if (mounted) {
        CustomSnackBar.show(
          context,
          "Notes updated from the server!",
          isSuccess: true,
        );
      }
    } else {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "No Internet Connection, Please connect and try again",
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: "MS Notes",
        backbutton: false,
        actions: [
          IconButton(
            onPressed: () {
              _enterSearch();
            },
            icon: const Icon(LineIcons.search),
          ),
        ],
      ),
      body: _notesBoxListenable == null
          ? LoadingStateWidget(
              message: "Loading MS Notes...",
              colorScheme: colorScheme,
            )
          : RefreshIndicator(
              backgroundColor: colorScheme.primary,
              color: colorScheme.surface,
              onRefresh: _refreshData,
              child: ValueListenableBuilder<Box<MSNote>>(
                valueListenable: _notesBoxListenable!,
                builder: (context, box, _) {
                  final subjects = _getSubjects(box);
                  return LayoutBuilder(
                    builder: (BuildContext context,
                        BoxConstraints viewportConstraints) {
                      return subjects.isEmpty
                          ? EmptyStateWidget(
                              title: 'No Subjects Found',
                              description:
                                  'Pull down to refresh and load notes from the server',
                              actionText: 'Swipe down to refresh',
                              icon: LineIcons.bookOpen,
                              colorScheme: colorScheme,
                            )
                          : _buildSubjectsList(subjects, colorScheme);
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildSubjectsList(List<String> subjects, ColorScheme colorScheme) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeaderWidget(
            title: "Available Subjects",
            subtitle:
                "${subjects.length} subject${subjects.length == 1 ? '' : 's'} available",
            icon: LineIcons.bookOpen,
            colorScheme: colorScheme,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return SubjectCardWidget(
                  subject: subjects[index],
                  onTap: () => _navigateToLectures(subjects[index]),
                  colorScheme: colorScheme,
                );
              },
              childCount: subjects.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  void _navigateToLectures(String subject) {
    debugPrint("Subject Selected: $subject");
    var box = Hive.box<MSNote>('notesBox');
    List<MSNote> subjectLectures = box.values
        .where((note) => note.subject == subject)
        .toList()
      ..sort((a, b) => a.lectureNumber.compareTo(b.lectureNumber));

    Navigator.push(
      context,
      PageTransition(
        child: LecturesScreen(
          subject: subject,
          lectures: subjectLectures,
        ),
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _enterSearch() {
    try {
      final currentNotes = _notesBox?.values.toList() ?? [];

      currentNotes
          .map((msNote) => NoteTakingModel(
                noteId: msNote.lectureNumber.toString(),
                noteTitle: msNote.lectureTitle,
                noteContent: msNote.lectureDescription + (msNote.body ?? ''),
                tags: [msNote.subject],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isDeleted: false,
                isSynced: true,
                userId: 'ms_notes',
                versionNumber: 1,
              ))
          .toList();

      Navigator.push(
        context,
        PageTransition(
          child: AdvancedSearchScreen(
            takingNotes: [],
            readingNotes: currentNotes,
            searchReadingNotes: true,
          ),
          type: PageTransitionType.bottomToTop,
          duration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      FlutterBugfender.log("Error entering search: $e");
      FlutterBugfender.error(e.toString());
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Error entering search: $e",
          isSuccess: false,
        );
      }
    }
  }
}
