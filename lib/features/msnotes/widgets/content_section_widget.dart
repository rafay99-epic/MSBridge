import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/widgets/html_render.dart';

class ContentSectionWidget extends StatelessWidget {
  final String? content;
  final ColorScheme colorScheme;

  const ContentSectionWidget({
    super.key,
    required this.content,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (content != null && content!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LineIcons.bookOpen,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Lecture Content",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            buildHtmlContent(
              content,
              ThemeData(
                colorScheme: colorScheme,
                textTheme: TextTheme(
                  bodyLarge: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    height: 1.6,
                  ),
                  bodyMedium: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              context,
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              LineIcons.exclamationTriangle,
              size: 64,
              color: colorScheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              "No Content Available",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This lecture doesn't have any content yet",
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}
