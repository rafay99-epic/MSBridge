import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/webview_repo.dart';
import 'package:msbridge/features/contact/contact.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/config/config.dart';
import 'package:msbridge/features/setting/section/appinfo_section/about_author_page.dart';

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
      FlutterBugfender.sendCrash(
          'Failed to get app version: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to get app version: $e');
      setState(() {
        appVersion = 'Not available';
        buildVersion = 'Not available';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SettingsSection(
      title: "App Info",
      children: [
        // App Version Info Cards
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Environment Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LineIcons.cogs,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Environment",
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Production",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // App Version Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.secondary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LineIcons.infoCircle,
                        color: colorScheme.onSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "App Version",
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appVersion,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Build Version Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LineIcons.tools,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Build Number",
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            buildVersion,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Action Tiles
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              // Contact Us
              _buildActionTile(
                context,
                title: "Contact Us",
                subtitle: "Get in touch with our support team",
                icon: LineIcons.envelope,
                iconColor: colorScheme.primary,
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

              // Divider
              Divider(
                height: 1,
                color: colorScheme.outline.withOpacity(0.2),
                indent: 16,
                endIndent: 16,
              ),

              // Privacy Policy
              _buildActionTile(
                context,
                title: "Privacy Policy",
                subtitle: "Learn about data protection",
                icon: LineIcons.userShield,
                iconColor: colorScheme.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: const MyCMSWebView(
                          pageTitle: "Privacy Policy",
                          cmsUrl: URL.prravicyPolicy),
                    ),
                  );
                },
              ),

              // Divider
              Divider(
                height: 1,
                color: colorScheme.outline.withOpacity(0.2),
                indent: 16,
                endIndent: 16,
              ),

              // Terms and Conditions
              _buildActionTile(
                context,
                title: "Terms and Conditions",
                subtitle: "Read our terms of service",
                icon: LineIcons.fileAlt,
                iconColor: colorScheme.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: const MyCMSWebView(
                          pageTitle: "Terms and Conditions",
                          cmsUrl: URL.termsOfService),
                    ),
                  );
                },
              ),

              // Divider
              Divider(
                height: 1,
                color: colorScheme.outline.withOpacity(0.2),
                indent: 16,
                endIndent: 16,
              ),

              // About Author
              _buildActionTile(
                context,
                title: "About Author",
                subtitle: "Learn more about the developer",
                icon: LineIcons.user,
                iconColor: colorScheme.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: const AboutAuthorPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        LineIcons.angleRight,
        color: colorScheme.onSurface.withOpacity(0.4),
        size: 18,
      ),
      onTap: onTap,
    );
  }
}
