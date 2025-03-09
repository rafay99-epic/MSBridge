import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/repo/webview_repo.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/changePassword/change_password.dart';
import 'package:msbridge/features/contact/contact.dart';
import 'package:msbridge/features/offline/offline.dart';
import 'package:msbridge/features/setting/delete/delete.dart';
import 'package:msbridge/features/setting/logout/logout_dialog.dart';
import 'package:msbridge/features/setting/settings_section.dart';
import 'package:msbridge/features/setting/settings_tile.dart';
import 'package:msbridge/features/setting/theme/theme_selector.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/widgets/warning_dialog_box.dart';
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
  bool isInternetConnected = false;
  final InternetHelper _internetHelper = InternetHelper();

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
    _internetHelper.connectivitySubject.listen((connected) {
      if (isInternetConnected != connected && mounted) {
        setState(() {
          isInternetConnected = connected;
        });
      }
    });
  }

  @override
  void dispose() {
    _internetHelper.dispose();
    super.dispose();
  }

  void _attemptGoOffline() async {
    _internetHelper.checkInternet();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted && isInternetConnected) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OfflineHome(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var fadeAnimation = animation.drive(tween);

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
        ),
      );

      CustomSnackBar.show(context, "Welcome Back: You are now Offline ");
    } else {
      if (mounted) {
        CustomSnackBar.show(
            context, "You are still Online: Sorry to be Online");
      }
    }
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

  Future<void> resetOfflineNotes() async {
    final result = await HiveNoteTakingRepo.clearBox();
    if (result == false) {
      CustomSnackBar.show(context, "Sorry Error occured!! Notes didn't reset");
    } else {
      CustomSnackBar.show(context, "Offline notes reset successfully.");
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
          SettingsSection(
            title: "Connectivity",
            children: [
              SettingsTile(
                title: "Internet Status",
                icon: isInternetConnected ? LineIcons.wifi : Icons.wifi_off,
                versionNumber:
                    isInternetConnected ? "Connected" : "Disconnected",
              ),
              SettingsTile(
                title: "Go Offline Mode",
                icon: LineIcons.cloud,
                onTap: _attemptGoOffline,
              ),
            ],
          ),
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
            SettingsTile(
              title: "Reset Offline Notes",
              icon: Icons.restart_alt,
              onTap: () => {
                showConfirmationDialog(
                  context,
                  theme,
                  () {
                    resetOfflineNotes();
                  },
                  "Reset Offline Notes",
                  "Are you sure you want to reset offline notes?",
                ),
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
