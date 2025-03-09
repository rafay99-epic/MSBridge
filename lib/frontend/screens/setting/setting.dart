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
import 'package:msbridge/frontend/screens/setting/theme/theme_selector.dart';
import 'package:msbridge/frontend/widgets/appbar.dart';
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
      appBar: const CustomAppBar(title: "Settings"),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SettingsSection(
            title: "Appearance",
            children: [
              SettingsTile(
                title: "Choose Theme",
                icon: LineIcons.palette,
                child: ThemeSelector(themeProvider: themeProvider),
              ),
            ],
          ),
          Divider(color: theme.colorScheme.primary),
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
}
