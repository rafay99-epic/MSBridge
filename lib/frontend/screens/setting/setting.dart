import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Settings"),
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle("User Settings", theme),
          _buildListTile("Logout", LineIcons.alternateSignOut, theme, () {}),
          _buildListTile("Change Password", LineIcons.lock, theme, () {}),
          Divider(color: theme.colorScheme.primary),
          _buildSectionTitle("App Info", theme),
          _buildListTile("Environment", LineIcons.cogs, theme, () {}),
          _buildListTile(
              "App Version: 1.0.0", LineIcons.infoCircle, theme, null),
          _buildListTile("App Build: 1001", LineIcons.tools, theme, null),
          _buildListTile("Contact Us", LineIcons.envelope, theme, () {}),
          Divider(color: theme.colorScheme.primary),
          _buildSectionTitle("Danger", theme),
          _buildListTile("Delete Account", LineIcons.trash, theme, () {}),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildListTile(
      String title, IconData icon, ThemeData theme, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: theme.colorScheme.secondary.withOpacity(0.2),
        highlightColor: theme.colorScheme.secondary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(icon, color: theme.colorScheme.secondary, size: 24),
            title:
                Text(title, style: TextStyle(color: theme.colorScheme.primary)),
            trailing: onTap != null
                ? Icon(LineIcons.angleRight,
                    size: 16, color: theme.colorScheme.primary)
                : null,
          ),
        ),
      ),
    );
  }
}
