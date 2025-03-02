// import 'package:flutter/material.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';
// import 'package:msbridge/backend/models/notes_model.dart';

// class LectureDetailScreen extends StatelessWidget {
//   final MSNote lecture;

//   const LectureDetailScreen({super.key, required this.lecture});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Lecture Number: ${lecture.lectureNumber}"),
//         backgroundColor: theme.colorScheme.surface,
//         foregroundColor: theme.colorScheme.primary,
//         elevation: 0,
//       ),
//       backgroundColor: theme.colorScheme.surface,
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               lecture.lectureTitle,
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.primary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Lecture Number: ${lecture.lectureNumber}",
//               style: TextStyle(
//                 fontSize: 16,
//                 color: theme.colorScheme.secondary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Published on: ${lecture.pubDate}",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: theme.colorScheme.secondary,
//               ),
//             ),
//             Divider(
//               thickness: 2,
//               height: 32,
//               color: theme.colorScheme.primary,
//             ),
//             SizedBox(
//               height: MediaQuery.of(context).size.height * 0.8,
//               child: Markdown(
//                 data: lecture.body,
//                 styleSheet: MarkdownStyleSheet(
//                   p: TextStyle(
//                     fontSize: 16,
//                     color: theme.colorScheme.primary,
//                     height: 1.6,
//                   ),
//                   h1: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.primary,
//                   ),
//                   h2: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.primary,
//                   ),
//                   strong: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.primary,
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:msbridge/backend/models/notes_model.dart';

class LectureDetailScreen extends StatelessWidget {
  final MSNote lecture;

  const LectureDetailScreen({super.key, required this.lecture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Debug print to check if body data is present
    print("Lecture Title: ${lecture.lectureTitle}");
    print("Lecture Number: ${lecture.lectureNumber}");
    print("Published on: ${lecture.pubDate}");
    print("Lecture Body: ${lecture.body}");

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
            Text(
              lecture.lectureTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Lecture Number: ${lecture.lectureNumber}",
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Published on: ${lecture.pubDate}",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.secondary,
              ),
            ),
            Divider(
              thickness: 2,
              height: 32,
              color: theme.colorScheme.primary,
            ),
            if (lecture.body != null &&
                lecture.body!.isNotEmpty) // Check if body is not empty
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Markdown(
                  data: lecture.body!,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                      height: 1.6,
                    ),
                    h1: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    h2: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    strong: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
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
