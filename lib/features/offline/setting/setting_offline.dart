import 'dart:async';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/setting/settings_section.dart';
import 'package:msbridge/features/setting/settings_tile.dart';
import 'package:msbridge/features/setting/theme/theme_selector.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/repo/auth_gate.dart';

class OfflineSetting extends StatefulWidget {
  const OfflineSetting({super.key});

  @override
  State<OfflineSetting> createState() => _OfflineSettingState();
}

class _OfflineSettingState extends State<OfflineSetting> {
  String appVersion = "Loading...";
  String buildVersion = "Loading...";
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

  void _attemptGoOnline() async {
    _internetHelper.checkInternet();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted && isInternetConnected) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthGate(),
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

      CustomSnackBar.show(context, "Welcome Back: You are now online ");
    } else {
      if (mounted) {
        CustomSnackBar.show(
            context, "You are still offline: Sorry to be offline ");
      }
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
                title: "Go Online Mode",
                icon: LineIcons.cloud,
                onTap: _attemptGoOnline,
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
          ]),
        ],
      ),
    );
  }
}
