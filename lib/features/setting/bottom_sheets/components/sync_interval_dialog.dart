// features/setting/components/sync_interval_dialog.dart
import 'package:flutter/material.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_section_header.dart';

class SyncIntervalDialog extends StatefulWidget {
  const SyncIntervalDialog({super.key, this.initialMinutes, this.title});

  final int? initialMinutes;
  final String? title;

  @override
  State<SyncIntervalDialog> createState() => _SyncIntervalDialogState();

  // Returns selected minutes (0,15,30,60) via bottom sheet
  static Future<int?> show(BuildContext context,
      {int? initialMinutes, String? title}) async {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SyncIntervalDialog(
        initialMinutes: initialMinutes,
        title: title,
      ),
    );
  }
}

class _SyncIntervalDialogState extends State<SyncIntervalDialog> {
  late int _selectedInterval;

  @override
  void initState() {
    super.initState();
    _selectedInterval = widget.initialMinutes ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BottomSheetBase(
      title: widget.title ?? 'Auto sync interval',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingSectionHeader(title: 'Choose Interval', icon: Icons.timer),
          const SizedBox(height: 12),
          _buildIntervalOption('Off', 0),
          const SizedBox(height: 8),
          _buildIntervalOption('Every 15 minutes', 15),
          const SizedBox(height: 8),
          _buildIntervalOption('Every 30 minutes', 30),
          const SizedBox(height: 8),
          _buildIntervalOption('Every 60 minutes', 60),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, _selectedInterval),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalOption(String label, int value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool selected = _selectedInterval == value;
    return InkWell
        (
      onTap: () => setState(() => _selectedInterval = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.secondary.withOpacity(0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? colorScheme.secondary
                : colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: _selectedInterval,
              activeColor: colorScheme.secondary,
              onChanged: (v) {
                if (v != null) setState(() => _selectedInterval = v);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  size: 18, color: colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}
