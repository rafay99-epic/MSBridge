import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/core/services/sync/streak_sync_service.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/streak_provider.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';

class StreakDisplayWidget extends StatelessWidget {
  final bool showExtendedInfo;
  final VoidCallback? onTap;
  final bool showAppBar;

  const StreakDisplayWidget({
    super.key,
    this.showExtendedInfo = false,
    this.onTap,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StreakProvider>(
      builder: (context, streakProvider, child) {
        if (streakProvider.isLoading) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            if (showAppBar) ...[
              CustomAppBar(
                title: "Streak Status",
                backbutton: true,
                actions: [
                  IconButton(
                    onPressed: () async {
                      try {
                        await streakProvider.refreshStreak();
                        if (context.mounted) {
                          CustomSnackBar.show(
                            context,
                            "Streak data refreshed!",
                            isSuccess: true,
                          );
                        }
                      } catch (e) {
                        FlutterBugfender.sendCrash(
                            'Failed to refresh streak: $e',
                            StackTrace.current.toString());
                        FlutterBugfender.error('Failed to refresh streak: $e');
                        if (context.mounted) {
                          CustomSnackBar.show(
                            context,
                            "Failed to refresh streak: $e",
                            isSuccess: false,
                          );
                        }
                      }
                    },
                    icon: const Icon(LineIcons.syncIcon),
                    tooltip: "Refresh Streak",
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Streak Display with Better Contrast
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Streak Icon with Consistent Color
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LineIcons.fire,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Streak Count with Bold Typography
                      Text(
                        '${streakProvider.currentStreakCount}',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: -1.0,
                                  height: 1.0,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // "Day Streak" Text with Better Contrast
                  Text(
                    'Day Streak',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 0.2,
                        ),
                  ),
                  if (showExtendedInfo) ...[
                    const SizedBox(height: 16),
                    _buildExtendedInfo(context, streakProvider),
                  ],
                  if (streakProvider.needsAttention) ...[
                    const SizedBox(height: 12),
                    _buildAttentionIndicator(context, streakProvider),
                  ],
                  // Action Buttons
                  if (onTap != null) ...[
                    const SizedBox(height: 16),
                    _buildActionButtons(context, streakProvider),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExtendedInfo(
      BuildContext context, StreakProvider streakProvider) {
    return Column(
      children: [
        // Longest Streak Row
        _buildInfoRow(
          context,
          icon: LineIcons.trophy,
          label: 'Longest Streak',
          value: '${streakProvider.longestStreakCount} days',
        ),
        const SizedBox(height: 12),
        // Streak Started Row
        _buildInfoRow(
          context,
          icon: LineIcons.calendar,
          label: 'Started',
          value: _formatDate(streakProvider.currentStreak.streakStartDate),
        ),
        const SizedBox(height: 12),
        // Last Activity Row
        _buildInfoRow(
          context,
          icon: LineIcons.clock,
          label: 'Last Activity',
          value: _formatDate(streakProvider.currentStreak.lastActivityDate),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        // Icon with Consistent Color
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        // Label
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
          ),
        ),
        // Value
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  Widget _buildAttentionIndicator(
      BuildContext context, StreakProvider streakProvider) {
    final isUrgent = streakProvider.isStreakAboutToEnd;
    final icon =
        isUrgent ? LineIcons.exclamationTriangle : LineIcons.infoCircle;
    final color = isUrgent ? Colors.orange : Colors.blue;
    final message = streakProvider.motivationalMessage;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Attention Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          // Message
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, StreakProvider streakProvider) {
    return Row(
      children: [
        // Refresh Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                // Pull latest from cloud then update local view
                await StreakSyncService().syncNow();
                await streakProvider.refreshStreak();
                if (context.mounted) {
                  CustomSnackBar.show(
                    context,
                    "Streak synced",
                    isSuccess: true,
                  );
                }
              } catch (e) {
                FlutterBugfender.sendCrash(
                    'Failed to sync streak: $e', StackTrace.current.toString());
                FlutterBugfender.error('Failed to sync streak: $e');
                if (context.mounted) {
                  CustomSnackBar.show(
                    context,
                    "Sync failed: $e",
                    isSuccess: false,
                  );
                }
              }
            },
            icon: const Icon(LineIcons.syncIcon, size: 18),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              foregroundColor: Theme.of(context).colorScheme.secondary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAtSameMomentAs(today)) {
      return "Today";
    } else if (dateOnly
        .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return "Yesterday";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
