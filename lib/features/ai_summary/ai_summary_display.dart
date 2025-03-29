import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiSummaryDisplay extends StatefulWidget {
  final String aiSummary;

  const AiSummaryDisplay({super.key, required this.aiSummary});

  @override
  State<AiSummaryDisplay> createState() => _AiSummaryDisplayState();
}

class _AiSummaryDisplayState extends State<AiSummaryDisplay> {
  String _displayText = '';
  bool _isTypingComplete = false;

  @override
  void initState() {
    super.initState();
    _startTypingEffect();
  }

  Future<void> _startTypingEffect() async {
    if (widget.aiSummary.isEmpty) {
      setState(() {
        _isTypingComplete = true;
      });
      return;
    }

    final lines = widget.aiSummary.split('\n');
    for (final line in lines) {
      for (int i = 0; i < line.length; i++) {
        if (!mounted) return;
        if (mounted) {
          setState(() {
            _displayText = _displayText + line[i];
          });
        }
        await Future.delayed(const Duration(milliseconds: 15));
      }
      if (!mounted) return;
      if (mounted) {
        setState(() {
          _displayText = '$_displayText\n';
        });
      }
      await Future.delayed(const Duration(milliseconds: 15));
    }

    if (mounted) {
      setState(() {
        _isTypingComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            MarkdownBody(
              key: ValueKey(_isTypingComplete),
              data: _displayText,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                h1: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
                h2: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
                h3: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
                h4: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
                code: TextStyle(
                  backgroundColor: Colors.grey[200],
                  fontSize: 14,
                ),
                tableHead: const TextStyle(fontWeight: FontWeight.bold),
                tableBody: theme.textTheme.bodyMedium,
                blockquote: const TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
