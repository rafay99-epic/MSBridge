import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/api/ms_notes_api.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/msnotes/lectures_screen.dart';
import 'package:msbridge/features/msnotes/widgets/loading_state_widget.dart';
import 'package:msbridge/features/msnotes/widgets/empty_state_widget.dart';
import 'package:msbridge/features/msnotes/widgets/section_header_widget.dart';
import 'package:msbridge/features/msnotes/widgets/subject_card_widget.dart';
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
        await ApiService.fetchAndSaveNotes();
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            "Error fetching notes: $e",
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

      if (mounted) {
        CustomSnackBar.show(
          context,
          "Notes updated from the server!",
        );
      }
    } else {
      if (mounted) {
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "MS Notes",
        backbutton: false,
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
}
