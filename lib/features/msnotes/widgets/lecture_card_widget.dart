import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';

class LectureCardWidget extends StatelessWidget {
  final MSNote lecture;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const LectureCardWidget({
    super.key,
    required this.lecture,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    DateTime pubDate = DateTime.parse(lecture.pubDate).toLocal();
    String formattedDate = DateFormat('MMMM d, yyyy').format(pubDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest, // Match search screen color
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                colorScheme.shadow.withValues(alpha: 0.2), // Increased shadow opacity
            blurRadius: 12, // Increased blur for better depth
            offset: const Offset(0, 6), // Increased offset for better elevation
          ),
        ],
        border: Border.all(
          color: colorScheme.primary
              .withValues(alpha: 0.3), // Match search screen border color
          width: 2, // Match search screen border width
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary
                            .withValues(alpha: 0.15), // Slightly more prominent
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          // Add border to lecture number container
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        lecture.lectureNumber.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        lecture.lectureTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight
                              .w700, // Increased weight for better visibility
                          color: colorScheme.onSurface,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Container(
                      // Wrap arrow icon in styled container
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        LineIcons.angleRight,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                if (lecture.lectureDescription.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    // Wrap description in styled container
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      lecture.lectureDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      // Wrap calendar icon in styled container
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.secondary.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        LineIcons.calendar,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Published: $formattedDate",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600, // Increased weight
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary
                            .withValues(alpha: 0.15), // Slightly more prominent
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          // Add border to "Tap to read" container
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "Tap to read",
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700, // Increased weight
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
