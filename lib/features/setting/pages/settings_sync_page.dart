// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:msbridge/features/setting/section/sync_section/settings_sync_section.dart';
import 'package:msbridge/widgets/appbar.dart';

class SettingsSyncPage extends StatelessWidget {
  const SettingsSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Settings Sync',
        backbutton: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: SettingsSyncSection(),
        ),
      ),
    );
  }
}
