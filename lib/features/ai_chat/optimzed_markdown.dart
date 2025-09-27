import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class OptimizedMarkdownBody extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet styleSheet;

  const OptimizedMarkdownBody({
    super.key,
    required this.data,
    required this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      selectable: true,
      imageBuilder: (uri, title, alt) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Image.network(
            uri.toString(),
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';

// class OptimizedMarkdownBody extends StatelessWidget {
//   final String data;
//   final MarkdownStyleSheet styleSheet;

//   const OptimizedMarkdownBody({
//     super.key,
//     required this.data,
//     required this.styleSheet,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return MarkdownBody(
//       data: data,
//       styleSheet: styleSheet,
//       selectable: true,
//       builders: MarkdownBuilderDelegate(
//         builders: {
//           'img': MarkdownElementBuilder(
//             builder: (context, element, textContent) {
//               final src = element.attributes['src'] ?? '';
//               return ConstrainedBox(
//                 constraints: const BoxConstraints(maxHeight: 200),
//                 child: Image.network(
//                   src,
//                   frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
//                     if (wasSynchronouslyLoaded) return child;
//                     return AnimatedOpacity(
//                       opacity: frame == null ? 0 : 1,
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeOut,
//                       child: child,
//                     );
//                   },
//                 ),
//               );
//             },
//           ),
//         },
//       ),
//     );
//   }
// }