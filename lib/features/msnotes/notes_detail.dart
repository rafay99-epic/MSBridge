// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/features/msnotes/widgets/content_section_widget.dart';
import 'package:msbridge/features/msnotes/widgets/lecture_header_widget.dart';
import 'package:msbridge/widgets/appbar.dart';

class LectureDetailScreen extends StatelessWidget {
  final MSNote lecture;

  const LectureDetailScreen({super.key, required this.lecture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Lecture ${lecture.lectureNumber}",
        backbutton: true,
      ),
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LectureHeaderWidget(
                    lecture: lecture,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 24),
                  ContentSectionWidget(
                    content: lecture.body,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
