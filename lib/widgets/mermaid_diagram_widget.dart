// Flutter imports:
import 'package:flutter/material.dart';

class MermaidDiagramWidget extends StatelessWidget {
  final String mermaidCode;
  final ColorScheme colorScheme;

  const MermaidDiagramWidget({
    super.key,
    required this.mermaidCode,
    required this.colorScheme,
  });

  String _getCleanCode() {
    return mermaidCode
        .replaceAll('```mermaid', '')
        .replaceAll('```', '')
        .trim();
  }

  String _getDiagramType() {
    final cleanCode = _getCleanCode();
    if (cleanCode.startsWith('graph')) return 'Flowchart';
    if (cleanCode.startsWith('stateDiagram')) return 'State Diagram';
    if (cleanCode.startsWith('sequenceDiagram')) return 'Sequence Diagram';
    if (cleanCode.startsWith('classDiagram')) return 'Class Diagram';
    if (cleanCode.startsWith('gantt')) return 'Gantt Chart';
    if (cleanCode.startsWith('pie')) return 'Pie Chart';
    if (cleanCode.startsWith('journey')) return 'User Journey';
    return 'Diagram';
  }

  IconData _getDiagramIcon() {
    final cleanCode = _getCleanCode();
    if (cleanCode.startsWith('graph')) return Icons.account_tree;
    if (cleanCode.startsWith('stateDiagram')) return Icons.trip_origin;
    if (cleanCode.startsWith('sequenceDiagram')) return Icons.timeline;
    if (cleanCode.startsWith('classDiagram')) return Icons.class_;
    if (cleanCode.startsWith('gantt')) return Icons.calendar_view_month;
    if (cleanCode.startsWith('pie')) return Icons.pie_chart;
    if (cleanCode.startsWith('journey')) return Icons.route;
    return Icons.account_tree;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with diagram type and badge
          Row(
            children: [
              Icon(
                _getDiagramIcon(),
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getDiagramType(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.code,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Mermaid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Diagram preview placeholder
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getDiagramIcon(),
                  size: 48,
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  '📊 ${_getDiagramType()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visual diagram representation',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Code section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.code,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mermaid Code',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.copy,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 14,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      _getCleanCode(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Info message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a Mermaid diagram. To see the visual representation, copy the code above and paste it into a Mermaid-compatible viewer like mermaid.live or GitHub.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.primary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
