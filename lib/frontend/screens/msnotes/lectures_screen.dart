import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:msbridge/backend/hive/notes_model.dart';
import 'package:msbridge/frontend/screens/msnotes/notes_detail.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(subject),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: lectures.isEmpty
          ? const Center(
              child: Text("No Lectures Available"),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lectures.length,
              itemBuilder: (context, index) {
                final lecture = lectures[index];
                DateTime pubDate = DateTime.parse(lecture.pubDate).toLocal();
                String formattedDate =
                    DateFormat('MMMM d, yyyy').format(pubDate);
                return Card(
                  color: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      "${lecture.lectureNumber}. ${lecture.lectureTitle}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lecture.lectureDescription,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Published on: $formattedDate",
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => {
                      debugPrint("Lecture Selected: ${lecture.lectureTitle}"),
                      Navigator.push(
                        context,
                        PageTransition(
                          child: LectureDetailScreen(lecture: lecture),
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                        ),
                      )
                    },
                  ),
                );
              },
            ),
    );
  }
}
