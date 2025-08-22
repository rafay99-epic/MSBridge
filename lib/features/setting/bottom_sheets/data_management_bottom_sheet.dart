// features/setting/bottom_sheets/data_management_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/services/backup_service.dart';
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';

class DataManagementBottomSheet extends StatelessWidget {
  const DataManagementBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: "Data Management",
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        SettingActionTile(
          title: "Export Backup",
          subtitle: "Create a backup of all your notes",
          icon: LineIcons.download,
          onTap: () => _exportBackup(context),
        ),
        const SizedBox(height: 12),
        SettingActionTile(
          title: "Import Backup",
          subtitle: "Restore notes from a backup file",
          icon: LineIcons.upload,
          onTap: () => _importBackup(context),
        ),
        const SizedBox(height: 12),
        SettingActionTile(
          title: "Recycle Bin",
          subtitle: "View and restore deleted notes",
          icon: LineIcons.trash,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const DeletedNotes(),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final filePath = await BackupService.exportAllNotes(context);
      if (context.mounted) {
        final detailedLocation =
            BackupService.getDetailedFileLocation(filePath);
        CustomSnackBar.show(
          context,
          'Backup exported successfully to $detailedLocation',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          'Backup failed: $e',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final report = await BackupService.importFromFile();
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          'Import: ${report.inserted} added, ${report.updated} updated, ${report.skipped} skipped',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          'Import failed: $e',
          isSuccess: false,
        );
      }
    }
  }
}
