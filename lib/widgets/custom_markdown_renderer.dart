import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:msbridge/widgets/mermaid_diagram_widget.dart';

class CustomMarkdownRenderer extends StatelessWidget {
  final String data;
  final ColorScheme colorScheme;
  final bool shrinkWrap;

  const CustomMarkdownRenderer({
    super.key,
    required this.data,
    required this.colorScheme,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the content contains mermaid diagrams
    if (_containsMermaidDiagrams(data)) {
      return _buildWithMermaidSupport(context);
    }

    // Fall back to regular markdown rendering
    return MarkdownWidget(
      data: data,
      shrinkWrap: shrinkWrap,
    );
  }

  bool _containsMermaidDiagrams(String content) {
    return content.contains('```mermaid') ||
        content.contains('```mermaid\n') ||
        content.contains('graph ') ||
        content.contains('stateDiagram') ||
        content.contains('sequenceDiagram') ||
        content.contains('classDiagram') ||
        content.contains('flowchart') ||
        content.contains('gantt') ||
        content.contains('pie') ||
        content.contains('journey') ||
        content.contains('gitgraph');
  }

  Widget _buildWithMermaidSupport(BuildContext context) {
    // Split content by mermaid code blocks
    final parts = _splitByMermaidBlocks(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        if (part.isMermaid) {
          return MermaidDiagramWidget(
            mermaidCode: part.content,
            colorScheme: colorScheme,
          );
        } else {
          return MarkdownWidget(
            data: part.content,
            shrinkWrap: true,
          );
        }
      }).toList(),
    );
  }

  List<ContentPart> _splitByMermaidBlocks(String content) {
    final List<ContentPart> parts = [];
    final RegExp mermaidRegex = RegExp(r'```mermaid\s*\n([\s\S]*?)```');

    int lastIndex = 0;
    final matches = mermaidRegex.allMatches(content);

    for (final match in matches) {
      // Add text before mermaid block
      if (match.start > lastIndex) {
        final textBefore = content.substring(lastIndex, match.start);
        if (textBefore.trim().isNotEmpty) {
          parts.add(ContentPart(content: textBefore, isMermaid: false));
        }
      }

      // Add mermaid block

      final mermaidContent = (match.group(1) ?? '').trim();
      if (mermaidContent.isNotEmpty) {
        parts.add(ContentPart(content: mermaidContent, isMermaid: true));
      }

      lastIndex = match.end;
    }

    // Add remaining text after last mermaid block
    if (lastIndex < content.length) {
      final remainingText = content.substring(lastIndex);
      if (remainingText.trim().isNotEmpty) {
        parts.add(ContentPart(content: remainingText, isMermaid: false));
      }
    }

    // If no mermaid blocks found, return original content as single part
    if (parts.isEmpty) {
      parts.add(ContentPart(content: content, isMermaid: false));
    }

    return parts;
  }
}

class ContentPart {
  final String content;
  final bool isMermaid;

  ContentPart({
    required this.content,
    required this.isMermaid,
  });
}
