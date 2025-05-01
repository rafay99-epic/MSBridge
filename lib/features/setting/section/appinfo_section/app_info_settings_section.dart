import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/webview_repo.dart';
import 'package:msbridge/features/contact/contact.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:page_transition/page_transition.dart';

class AppInfoSettingsSection extends StatefulWidget {
  const AppInfoSettingsSection({super.key});

  @override
  State<AppInfoSettingsSection> createState() => _AppInfoSettingsSectionState();
}

class _AppInfoSettingsSectionState extends State<AppInfoSettingsSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String appVersion = "Loading...";
  String buildVersion = "Loading...";

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

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
  Widget build(BuildContext context) {
    super.build(context);

    return SettingsSection(
      title: "App Info",
      children: [
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
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: ContactPage(),
              ),
            );
          },
        ),
        SettingsTile(
          title: "Privacy Policy",
          icon: LineIcons.userShield,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const MyCMSWebView(
                    pageTitle: "Privacy Policy",
                    cmsUrl: "https://ms-bridge-app.vercel.app/privacy"),
              ),
            );
          },
        ),
        SettingsTile(
          title: "Terms and Conditions",
          icon: LineIcons.fileAlt,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const MyCMSWebView(
                    pageTitle: "Terms and Conditions",
                    cmsUrl: "https://ms-bridge-app.vercel.app/terms"),
              ),
            );
          },
        ),
      ],
    );
  }
}
