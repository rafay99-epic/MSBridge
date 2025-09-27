import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';

class LectureHeaderWidget extends StatelessWidget {
  final MSNote lecture;
  final ColorScheme colorScheme;

  const LectureHeaderWidget({
    super.key,
    required this.lecture,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    DateTime pubDate = DateTime.parse(lecture.pubDate).toLocal();
    String formattedDate = DateFormat('MMMM d, yyyy').format(pubDate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LineIcons.fileAlt,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lecture ${lecture.lectureNumber}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      "Published on $formattedDate",
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            lecture.lectureTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          if (lecture.lectureDescription.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              lecture.lectureDescription,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
