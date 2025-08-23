import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/features/setting/widgets/search_results_widget.dart';
import 'package:msbridge/features/setting/widgets/profile_header_widget.dart';
import 'package:msbridge/features/setting/widgets/quick_actions_widget.dart';
import 'package:msbridge/features/setting/widgets/settings_section_widget.dart';
import 'package:msbridge/features/setting/widgets/danger_admin_widgets.dart';
import 'package:msbridge/features/setting/widgets/app_bar_widget.dart';
import 'package:msbridge/features/setting/widgets/navigation_methods.dart';
import 'package:msbridge/widgets/streak_display_widget.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/streak_provider.dart';

// Searchable setting item model
class SearchableSetting {
  final String title;
  final String subtitle;
  final IconData icon;
  final String section;
  final VoidCallback onTap;

  SearchableSetting({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.section,
    required this.onTap,
  });
}

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchableSetting> _searchResults = [];
  bool _isSearching = false;
  List<SearchableSetting> _allSettings = [];

  @override
  void initState() {
    super.initState();
    _initializeSearchableSettings();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initializeSearchableSettings() {
    _allSettings = [
      // Account & Security
      SearchableSetting(
        title: "Profile Management",
        subtitle: "Edit profile, change password, and logout",
        icon: LineIcons.user,
        section: "Account & Security",
        onTap: () => NavigationMethods.navigateToProfile(context),
      ),
      SearchableSetting(
        title: "Security",
        subtitle: "PIN lock, fingerprint, and password",
        icon: LineIcons.userShield,
        section: "Account & Security",
        onTap: () => NavigationMethods.navigateToSecurity(context),
      ),
      SearchableSetting(
        title: "Theme & Appearance",
        subtitle: "Customize app colors and style",
        icon: LineIcons.palette,
        section: "Account & Security",
        onTap: () => NavigationMethods.navigateToAppearance(context),
      ),

      // Notes & Sharing
      SearchableSetting(
        title: "AI & Smart Features",
        subtitle: "AI models, auto-save, and summaries",
        icon: LineIcons.robot,
        section: "Notes & Sharing",
        onTap: () => NavigationMethods.navigateToAISmartFeatures(context),
      ),
      SearchableSetting(
        title: "Templates",
        subtitle: "Enable, sync, and pull templates from cloud",
        icon: LineIcons.clone,
        section: "Notes & Sharing",
        onTap: () => NavigationMethods.navigateToTemplatesSettings(context),
      ),
      SearchableSetting(
        title: "Notes & Sharing",
        subtitle: "Chat history and shareable links",
        icon: LineIcons.comments,
        section: "Notes & Sharing",
        onTap: () => NavigationMethods.navigateToNotesSettings(context),
      ),
      SearchableSetting(
        title: "Sync & Cloud",
        subtitle: "Firebase sync and backup options",
        icon: LineIcons.cloud,
        section: "Notes & Sharing",
        onTap: () => NavigationMethods.navigateToSyncSettings(context),
      ),
      SearchableSetting(
        title: "Data Management",
        subtitle: "Export, import, and recycle bin",
        icon: LineIcons.database,
        section: "Notes & Sharing",
        onTap: () => NavigationMethods.navigateToDataManagement(context),
      ),
      SearchableSetting(
        title: "Streak Settings",
        subtitle: "Track daily note creation and get motivated",
        icon: LineIcons.fire,
        section: "Streak & Motivation",
        onTap: () => NavigationMethods.navigateToStreakSettings(context),
      ),

      // System
      SearchableSetting(
        title: "App Updates",
        subtitle: "Download latest versions",
        icon: LineIcons.download,
        section: "System",
        onTap: () => NavigationMethods.navigateToUpdateApp(context),
      ),
      SearchableSetting(
        title: "App Information",
        subtitle: "Version details and support",
        icon: LineIcons.info,
        section: "System",
        onTap: () => NavigationMethods.navigateToAppInfo(context),
      ),

      // Danger Zone
      SearchableSetting(
        title: "Delete Account",
        subtitle: "Permanently remove your account and all data",
        icon: LineIcons.trash,
        section: "Danger Zone",
        onTap: () => NavigationMethods.navigateToDeleteAccount(context),
      ),
      SearchableSetting(
        title: "Reset App Theme",
        subtitle: "Restore default theme settings",
        icon: Icons.palette_outlined,
        section: "Danger Zone",
        onTap: () => NavigationMethods.navigateToResetTheme(context),
      ),

      // Admin Section
      SearchableSetting(
        title: "Tina CMS",
        subtitle: "Manage website content and structure",
        icon: LineIcons.edit,
        section: "Admin",
        onTap: () => NavigationMethods.navigateToTinaCMS(context),
      ),
      SearchableSetting(
        title: "Page CMS",
        subtitle: "Manage page content and layouts",
        icon: LineIcons.pen,
        section: "Admin",
        onTap: () => NavigationMethods.navigateToPageCMS(context),
      ),
      SearchableSetting(
        title: "Contact Messages",
        subtitle: "View and manage user feedback",
        icon: LineIcons.users,
        section: "Admin",
        onTap: () => NavigationMethods.navigateToContactMessages(context),
      ),
    ];
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = _allSettings.where((setting) {
          return setting.title.toLowerCase().contains(query) ||
              setting.subtitle.toLowerCase().contains(query) ||
              setting.section.toLowerCase().contains(query);
        }).toList();
      } else {
        _searchResults.clear();
      }
    });
  }

  void _enterSearch() {
    setState(() {
      _isSearching = true;
    });

    // Focus the search field immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _exitSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: AppBarWidgets.buildAppBarTitle(
            theme,
            _isSearching,
            _searchController,
            _searchFocusNode,
          ),
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.primary,
          elevation: 1,
          shadowColor: colorScheme.shadow.withOpacity(0.2),
          centerTitle: true,
          leading: AppBarWidgets.buildAppBarLeading(_isSearching, _exitSearch),
          actions: AppBarWidgets.buildAppBarActions(_isSearching, _enterSearch),
          titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        body: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            // Add keyboard shortcut for search (Ctrl+F or Cmd+F)
            if ((HardwareKeyboard.instance.isControlPressed ||
                    HardwareKeyboard.instance.isMetaPressed) &&
                event.logicalKey.keyLabel == 'F') {
              _enterSearch();
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Search Results or Normal Settings
                if (_isSearching)
                  SearchResultsWidget(
                    searchResults: _searchResults,
                    theme: theme,
                    colorScheme: colorScheme,
                  )
                else ...[
                  // Profile Header Section
                  ProfileHeaderWidget(
                    theme: theme,
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: 24),

                  // Streak Display Section
                  Consumer<StreakProvider>(
                    builder: (context, streakProvider, child) {
                      if (streakProvider.isLoading) {
                        return const SizedBox.shrink();
                      }

                      if (!streakProvider.streakEnabled) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: StreakDisplayWidget(
                              showExtendedInfo: false,
                              showAppBar: false,
                              onTap: () =>
                                  NavigationMethods.navigateToStreakSettings(
                                      context),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // Quick Actions
                  QuickActionsWidget(
                    theme: theme,
                    colorScheme: colorScheme,
                    onLogout: () => NavigationMethods.logoutUser(context),
                    onSyncNow: () async =>
                        await NavigationMethods.syncNow(context),
                    onPullFromCloud: () async =>
                        await NavigationMethods.pullFromCloud(context),
                    onBackup: () => NavigationMethods.createBackup(context),
                  ),

                  const SizedBox(height: 24),

                  // Main Settings Sections
                  SettingsSectionWidget(
                    title: "Account & Security",
                    children: [
                      SettingsTile(
                        title: "Profile Management",
                        subtitle: "Edit profile, change password, and logout",
                        icon: LineIcons.user,
                        onTap: () =>
                            NavigationMethods.navigateToProfile(context),
                      ),
                      SettingsTile(
                        title: "Security",
                        subtitle: "PIN lock, fingerprint, and password",
                        icon: LineIcons.userShield,
                        onTap: () =>
                            NavigationMethods.navigateToSecurity(context),
                      ),
                      SettingsTile(
                        title: "Theme & Appearance",
                        subtitle: "Customize app colors and style",
                        icon: LineIcons.palette,
                        onTap: () =>
                            NavigationMethods.navigateToAppearance(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SettingsSectionWidget(
                    title: "Notes & Sharing",
                    children: [
                      SettingsTile(
                        title: "AI & Smart Features",
                        subtitle: "AI models, auto-save, and summaries",
                        icon: LineIcons.robot,
                        onTap: () =>
                            NavigationMethods.navigateToAISmartFeatures(
                                context),
                      ),
                      SettingsTile(
                        title: "Templates",
                        subtitle: "Enable, sync, and pull templates from cloud",
                        icon: LineIcons.clone,
                        onTap: () =>
                            NavigationMethods.navigateToTemplatesSettings(
                                context),
                      ),
                      SettingsTile(
                        title: "Notes & Sharing",
                        subtitle: "Chat history and shareable links",
                        icon: LineIcons.comments,
                        onTap: () =>
                            NavigationMethods.navigateToNotesSettings(context),
                      ),
                      SettingsTile(
                        title: "Sync & Cloud",
                        subtitle: "Firebase sync and backup options",
                        icon: LineIcons.cloud,
                        onTap: () =>
                            NavigationMethods.navigateToSyncSettings(context),
                      ),
                      SettingsTile(
                        title: "Data Management",
                        subtitle: "Export, import, and recycle bin",
                        icon: LineIcons.database,
                        onTap: () =>
                            NavigationMethods.navigateToDataManagement(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Streak & Motivation Section
                  SettingsSectionWidget(
                    title: "Streak & Motivation",
                    children: [
                      SettingsTile(
                        title: "Streak Settings",
                        subtitle: "Track daily note creation and get motivated",
                        icon: LineIcons.fire,
                        onTap: () =>
                            NavigationMethods.navigateToStreakSettings(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SettingsSectionWidget(
                    title: "System",
                    children: [
                      if (FeatureFlag.enableInAppUpdate)
                        SettingsTile(
                          title: "App Updates",
                          subtitle: "Download latest versions",
                          icon: LineIcons.download,
                          onTap: () =>
                              NavigationMethods.navigateToUpdateApp(context),
                        ),
                      SettingsTile(
                        title: "App Information",
                        subtitle: "Version details and support",
                        icon: LineIcons.info,
                        onTap: () =>
                            NavigationMethods.navigateToAppInfo(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Danger Zone
                  DangerAdminWidgets.buildDangerSection(
                      context, theme, colorScheme),

                  const SizedBox(height: 24),

                  // Admin Section
                  DangerAdminWidgets.buildAdminSection(
                      context, theme, colorScheme),

                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
