// features/setting/bottom_sheet_manager.dart
import 'package:flutter/material.dart';
import 'package:msbridge/features/setting/bottom_sheets/ai_features_bottom_sheet.dart';
import 'package:msbridge/features/setting/bottom_sheets/appearance_bottom_sheet.dart';
import 'package:msbridge/features/setting/bottom_sheets/data_management_bottom_sheet.dart';
import 'package:msbridge/features/setting/bottom_sheets/notes_bottom_sheet.dart';
import 'package:msbridge/features/setting/bottom_sheets/profile_management_bottom_sheet.dart';
import 'package:msbridge/features/setting/bottom_sheets/security_bottom_sheet.dart';
import 'package:msbridge/features/setting/bottom_sheets/sync_bottom_sheet.dart';
import 'package:msbridge/features/setting/bottom_sheets/templates_bottom_sheet.dart';
import 'package:msbridge/features/setting/bottom_sheets/background_sync_bottom_sheet.dart';
import 'package:msbridge/features/setting/bottom_sheets/voice_notes_bottom_sheet.dart';

class BottomSheetManager {
  static Future<void> showAIFeaturesBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIFeaturesBottomSheet(),
    );
  }

  static Future<void> showSecurityBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SecurityBottomSheet(),
    );
  }

  static Future<void> showSyncBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SyncBottomSheet(),
    );
  }

  static Future<void> showDataManagementBottomSheet(
      BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DataManagementBottomSheet(),
    );
  }

  static Future<void> showNotesBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotesBottomSheet(),
    );
  }

  static Future<void> showAppearanceBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AppearanceBottomSheet(),
    );
  }

  static Future<void> showProfileManagementBottomSheet(
      BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileManagementBottomSheet(),
    );
  }

  static Future<void> showTemplatesBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TemplatesBottomSheet(),
    );
  }

  static Future<void> showVoiceNotesBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceNotesBottomSheet(),
    );
  }

  static Future<void> showBackgroundSyncBottomSheet(
      BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BackgroundSyncBottomSheet(),
    );
  }
}
