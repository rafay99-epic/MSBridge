import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:msbridge/backend/models/notes_model.dart';

class LectureDetailScreen extends StatelessWidget {
  final MSNote lecture;

  const LectureDetailScreen({super.key, required this.lecture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Format the date
    DateTime pubDate = DateTime.parse(lecture.pubDate).toLocal();
    String formattedDate = DateFormat('MMMM d, yyyy').format(pubDate);

    return Scaffold(
      appBar: AppBar(
        title: Text("Lecture Number: ${lecture.lectureNumber}"),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    lecture.lectureTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Published on: $formattedDate",
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(
              thickness: 2,
              height: 32,
              color: theme.colorScheme.primary,
            ),
            if (lecture.body != null && lecture.body!.isNotEmpty)
              Html(
                data: lecture.body!,
                style: {
                  "body": Style(
                    fontSize: FontSize(16),
                    color: theme.colorScheme.primary,
                    lineHeight: LineHeight.number(1.6),
                    textAlign: TextAlign.justify,
                  ),
                  "h1": Style(
                    fontSize: FontSize(24),
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  "h2": Style(
                    fontSize: FontSize(20),
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  "strong": Style(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                },
              )
            else
              const Center(
                child: Text(
                  "No content available",
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
