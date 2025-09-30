// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:line_icons/line_icons.dart';

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
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with typing indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LineIcons.checkCircle,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!_isTypingComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Typing...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Markdown content
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              child: MarkdownBody(
                key: ValueKey(_isTypingComplete),
                data: _displayText,
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  // Paragraphs
                  p: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 1.6,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),

                  // Headings
                  h1: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    height: 1.3,
                    letterSpacing: -0.5,
                  ),
                  h2: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  h3: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    height: 1.3,
                  ),
                  h4: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    height: 1.3,
                  ),

                  // Code blocks
                  code: TextStyle(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    color: colorScheme.primary,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),

                  // Code blocks decoration
                  codeblockDecoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),

                  // Lists
                  listBullet: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),

                  // Tables
                  tableHead: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                  tableBody: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),

                  // Blockquotes
                  blockquote: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 16,
                    height: 1.5,
                  ),

                  // Blockquote decoration
                  blockquoteDecoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: colorScheme.primary,
                        width: 4,
                      ),
                    ),
                  ),

                  // Horizontal rules
                  horizontalRuleDecoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
