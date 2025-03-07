import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/backend/provider/theme_provider.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/backend/repo/webview_repo.dart';
import 'package:msbridge/frontend/screens/changePassword/change_password.dart';
import 'package:msbridge/frontend/screens/contact/contact.dart';
import 'package:msbridge/frontend/screens/setting/delete/delete.dart';
import 'package:msbridge/frontend/screens/setting/logout/logout_dialog.dart';
import 'package:msbridge/frontend/screens/setting/settings_section.dart';
import 'package:msbridge/frontend/screens/setting/settings_tile.dart';
import 'package:msbridge/frontend/theme/colors.dart';
import 'package:msbridge/frontend/widgets/snakbar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  String appVersion = "Loading...";
  String buildVersion = "Loading...";
  String _userRole = 'guest';
  final AuthRepo _authRepo = AuthRepo();

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
        buildVersion = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        appVersion = 'Not available';
        buildVersion = 'Not available';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final result = await _authRepo.getUserRole();
    if (result.error != null) {
      setState(() {
        _userRole = result.error!;
      });
    } else {
      CustomSnackBar.show(context, "User role loaded successfully.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

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
          SettingsSection(title: "Appearance", children: [
            SettingsTile(
              title: "Choose Theme",
              icon: LineIcons.palette,
              child: Container(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: AppTheme.values.map((theme) {
                    return _buildThemeButton(theme, themeProvider);
                  }).toList(),
                ),
              ),
            ),
          ]),
          SettingsSection(title: "User Settings", children: [
            SettingsTile(
              title: "Logout",
              icon: LineIcons.alternateSignOut,
              onTap: () => showLogoutDialog(context),
            ),
            SettingsTile(
              title: "Change Password",
              icon: LineIcons.lock,
              onTap: () => {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const Changepassword(),
                  ),
                )
              },
            ),
          ]),
          Divider(color: theme.colorScheme.primary),
          SettingsSection(title: "App Info", children: [
            const SettingsTile(
                title: "Environment:",
                versionNumber: "Production",
                icon: LineIcons.cogs),
            SettingsTile(
              title: "App Version:",
              icon: LineIcons.infoCircle,
              versionNumber: appVersion,
            ),
            SettingsTile(
              title: "App Build: ",
              icon: LineIcons.tools,
              versionNumber: buildVersion,
            ),
            SettingsTile(
              title: "Contact Us",
              icon: LineIcons.envelope,
              onTap: () => {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: ContactPage(),
                  ),
                )
              },
            ),
          ]),
          Divider(color: theme.colorScheme.primary),
          SettingsSection(title: "Danger", children: [
            SettingsTile(
              title: "Delete Account",
              icon: LineIcons.trash,
              onTap: () => {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const DeleteAccountScreen(),
                  ),
                )
              },
            ),
          ]),
          if (_userRole == 'owner' || _userRole == 'admin')
            Column(
              children: [
                Divider(color: theme.colorScheme.primary),
                SettingsSection(title: "Admin Settings", children: [
                  SettingsTile(
                    title: "Tina CMS",
                    icon: LineIcons.edit,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: const MyCMSWebView(
                              cmsUrl: "https://www.rafay99.com/admin"),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    title: "Page CMS",
                    icon: LineIcons.pen,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: const MyCMSWebView(
                              cmsUrl: "https://app.pagescms.org/sign-in"),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    title: "Contact Messages",
                    icon: LineIcons.users,
                    onTap: () {
                      CustomSnackBar.show(context, "Coming Soon");
                    },
                  ),
                ]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(AppTheme theme, ThemeProvider themeProvider) {
    final isSelected = theme == themeProvider.selectedTheme;

    Color backgroundColor;
    Color iconColor;
    IconData iconData;

    switch (theme) {
      case AppTheme.light:
        backgroundColor = Colors.white;
        iconColor = Colors.black;
        iconData = Icons.wb_sunny;
        break;
      case AppTheme.dark:
        backgroundColor = Colors.black;
        iconColor = Colors.white;
        iconData = Icons.brightness_2;
        break;
      case AppTheme.purpleHaze:
        backgroundColor = Colors.deepPurple.shade400;
        iconColor = Colors.white;
        iconData = Icons.brightness_3;
        break;
      case AppTheme.mintFresh:
        backgroundColor = Colors.greenAccent.shade400;
        iconColor = Colors.black;
        iconData = Icons.eco;
        break;
    }

    return GestureDetector(
      onTap: () {
        themeProvider.setTheme(theme);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2.0)
              : null,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Icon(iconData, size: 20.0, color: iconColor),
        ),
      ),
    );
  }
}
