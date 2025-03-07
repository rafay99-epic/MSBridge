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
          SettingsSection(
            title: "Appearance",
            children: [
              SettingsTile(
                title: "Choose Theme",
                icon: LineIcons.palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: AppTheme.values.map((theme) {
                        return _buildThemeButton(theme, themeProvider);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

    Map<AppTheme, Map<String, dynamic>> themeStyles = {
      AppTheme.light: {
        "background": Colors.white,
        "icon": Icons.wb_sunny,
        "tooltip": "Light Theme",
        "iconColor": Colors.black
      },
      AppTheme.dark: {
        "background": Colors.black,
        "icon": Icons.nightlight_round,
        "tooltip": "Dark Theme",
        "iconColor": Colors.white
      },
      AppTheme.purpleHaze: {
        "background": Colors.deepPurple.shade400,
        "icon": Icons.blur_on,
        "tooltip": "Purple Haze",
        "iconColor": Colors.white
      },
      AppTheme.mintFresh: {
        "background": Colors.greenAccent.shade400,
        "icon": Icons.spa,
        "tooltip": "Mint Fresh",
        "iconColor": Colors.black
      },
      AppTheme.midnightBlue: {
        "background": Colors.indigo.shade900,
        "icon": Icons.nightlight,
        "tooltip": "Midnight Blue",
        "iconColor": Colors.white
      },
      AppTheme.crimsonBlush: {
        "background": Colors.pink.shade400,
        "icon": Icons.favorite,
        "tooltip": "Crimson Blush",
        "iconColor": Colors.white
      },
      AppTheme.forestGreen: {
        "background": Colors.green.shade700,
        "icon": Icons.park,
        "tooltip": "Forest Green",
        "iconColor": Colors.white
      },
      AppTheme.oceanWave: {
        "background": Colors.blue.shade400,
        "icon": Icons.waves,
        "tooltip": "Ocean Wave",
        "iconColor": Colors.white
      },
      AppTheme.sunsetGlow: {
        "background": Colors.orangeAccent.shade400,
        "icon": Icons.wb_twilight,
        "tooltip": "Sunset Glow",
        "iconColor": Colors.black
      },
    };

    return Tooltip(
      message: themeStyles[theme]!['tooltip'],
      child: GestureDetector(
        onTap: () {
          themeProvider.setTheme(theme);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(8.0),
          width: 50.0,
          height: 50.0,
          decoration: BoxDecoration(
            color: themeStyles[theme]!['background'],
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2.0)
                : null,
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
            ],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                themeStyles[theme]!['icon'],
                color: themeStyles[theme]!['iconColor'],
                size: 28.0,
              ),
              if (isSelected)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Icon(
                    LineIcons.checkCircle,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
