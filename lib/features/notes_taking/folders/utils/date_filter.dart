import 'package:flutter/material.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';

enum DateFilter { all, today, last7, last30, thisMonth, custom }

class DateFilterSelection {
  DateFilter filter;
  DateTimeRange? customRange;
  DateFilterSelection({this.filter = DateFilter.all, this.customRange});
}

DateTimeRange computeRange(DateFilterSelection sel, DateTime now) {
  switch (sel.filter) {
    case DateFilter.today:
      final start = DateTime(now.year, now.month, now.day);
      return DateTimeRange(
          start: start, end: start.add(const Duration(days: 1)));
    case DateFilter.last7:
      return DateTimeRange(
          start: now.subtract(const Duration(days: 7)), end: now);
    case DateFilter.last30:
      return DateTimeRange(
          start: now.subtract(const Duration(days: 30)), end: now);
    case DateFilter.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      return DateTimeRange(start: start, end: end);
    case DateFilter.custom:
      final r = sel.customRange;
      if (r == null) {
        return DateTimeRange(start: DateTime(1970), end: now);
      }
      final start = DateTime(r.start.year, r.start.month, r.start.day);
      final endExclusive = DateTime(r.end.year, r.end.month, r.end.day)
          .add(const Duration(days: 1));
      return DateTimeRange(start: start, end: endExclusive);
    case DateFilter.all:
      return DateTimeRange(start: DateTime(1970), end: now);
  }
}

List<NoteTakingModel> applyDateFilter(
  List<NoteTakingModel> notes,
  DateFilterSelection sel,
) {
  if (sel.filter == DateFilter.all) return notes;
  final range = computeRange(sel, DateTime.now());
  return notes.where((n) {
    final ts = n.updatedAt;
    return !ts.isBefore(range.start) && ts.isBefore(range.end);
  }).toList();
}

Future<DateFilterSelection?> showDateFilterSheet(
  BuildContext context,
  DateFilterSelection current,
) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  return showModalBottomSheet<DateFilterSelection>(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      Future<void> pickCustom() async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 3),
          lastDate: DateTime(now.year + 1),
          initialDateRange: current.customRange ??
              DateTimeRange(
                start: DateTime(now.year, now.month, now.day)
                    .subtract(const Duration(days: 7)),
                end: DateTime(now.year, now.month, now.day),
              ),
        );
        if (picked != null && ctx.mounted) {
          Navigator.pop(
              ctx,
              DateFilterSelection(
                  filter: DateFilter.custom, customRange: picked));
        }
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tile(
                ctx,
                Icons.clear_all,
                'All dates',
                () => Navigator.pop(
                    ctx, DateFilterSelection(filter: DateFilter.all))),
            _tile(
                ctx,
                Icons.today,
                'Today',
                () => Navigator.pop(
                    ctx, DateFilterSelection(filter: DateFilter.today))),
            _tile(
                ctx,
                Icons.calendar_view_week,
                'Last 7 days',
                () => Navigator.pop(
                    ctx, DateFilterSelection(filter: DateFilter.last7))),
            _tile(
                ctx,
                Icons.calendar_view_month,
                'Last 30 days',
                () => Navigator.pop(
                    ctx, DateFilterSelection(filter: DateFilter.last30))),
            _tile(
                ctx,
                Icons.event_note,
                'This month',
                () => Navigator.pop(
                    ctx, DateFilterSelection(filter: DateFilter.thisMonth))),
            _tile(ctx, Icons.date_range, 'Custom range', pickCustom),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Widget _tile(BuildContext ctx, IconData icon, String text, VoidCallback onTap) {
  return ListTile(
    leading: Icon(icon),
    title: Text(text),
    onTap: onTap,
  );
}
