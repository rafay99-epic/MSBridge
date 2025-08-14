import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/features/msnotes/notes_detail.dart';
import 'package:msbridge/features/msnotes/widgets/empty_state_widget.dart';
import 'package:msbridge/features/msnotes/widgets/section_header_widget.dart';
import 'package:msbridge/features/msnotes/widgets/lecture_card_widget.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:page_transition/page_transition.dart';

class LecturesScreen extends StatelessWidget {
  final String subject;
  final List<MSNote> lectures;

  const LecturesScreen({
    super.key,
    required this.subject,
    required this.lectures,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: subject,
        backbutton: true,
      ),
      backgroundColor: colorScheme.surface,
      body: lectures.isEmpty
          ? EmptyStateWidget(
              title: "No Lectures Available",
              description: "This subject doesn't have any lectures yet",
              actionText: "Go back",
              icon: LineIcons.fileAlt,
              colorScheme: colorScheme,
            )
          : _buildLecturesList(colorScheme),
    );
  }

  Widget _buildLecturesList(ColorScheme colorScheme) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeaderWidget(
            title: "Lectures",
            subtitle:
                "${lectures.length} lecture${lectures.length == 1 ? '' : 's'} available",
            icon: LineIcons.fileAlt,
            colorScheme: colorScheme,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: lectures.length,
            itemBuilder: (context, index) {
              return LectureCardWidget(
                lecture: lectures[index],
                onTap: () => _navigateToLectureDetail(context, lectures[index]),
                colorScheme: colorScheme,
              );
            },
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  void _navigateToLectureDetail(BuildContext context, MSNote lecture) {
    debugPrint("Lecture Selected: ${lecture.lectureTitle}");
    Navigator.push(
      context,
      PageTransition(
        child: LectureDetailScreen(lecture: lecture),
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}
