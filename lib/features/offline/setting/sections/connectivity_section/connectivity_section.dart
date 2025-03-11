import 'dart:async';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/core/repo/auth_gate.dart';
import 'package:msbridge/widgets/snakbar.dart';

class OfflineConnectivitySettingsSection extends StatefulWidget {
  const OfflineConnectivitySettingsSection({super.key});

  @override
  State<OfflineConnectivitySettingsSection> createState() =>
      _ConnectivitySettingsSectionState();
}

class _ConnectivitySettingsSectionState
    extends State<OfflineConnectivitySettingsSection> {
  bool _isInternetConnected = false;
  final InternetHelper _internetHelper = InternetHelper();

  @override
  void initState() {
    super.initState();
    _internetHelper.connectivitySubject.listen((connected) {
      if (_isInternetConnected != connected && mounted) {
        setState(() {
          _isInternetConnected = connected;
        });
      }
    });
  }

  @override
  void dispose() {
    _internetHelper.dispose();
    super.dispose();
  }

  void _attemptGoOnline(BuildContext context) async {
    _internetHelper.checkInternet();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted && _isInternetConnected) {
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
    return SettingsSection(
      title: "Connectivity",
      children: [
        SettingsTile(
          title: "Internet Status",
          icon: _isInternetConnected ? LineIcons.wifi : Icons.wifi_off,
          versionNumber: _isInternetConnected ? "Connected" : "Disconnected",
        ),
        SettingsTile(
          title: "Go Online Mode",
          icon: LineIcons.cloud,
          onTap: () => _attemptGoOnline(context),
        ),
      ],
    );
  }
}
