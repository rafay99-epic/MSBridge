import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/msnotes/msnotes.dart';
import 'package:msbridge/features/notes_taking/notetaking.dart';
import 'package:msbridge/features/ai_chat/chat_page.dart';
import 'package:msbridge/features/setting/section/search/search_setting.dart';
import 'package:msbridge/core/services/delete/deletion_sync_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  PageController? _pageController;

  final List<Widget?> _pages = List.filled(5, null);
  final List<bool> _pagesLoaded = List.filled(5, false);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    _pagesLoaded[0] = true;
    _pages[0] = const Msnotes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeletionSync();
    });
  }

  Future<void> _initializeDeletionSync() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await DeletionSyncHelper.initializeForUser(user.uid);
      }
    } catch (e) {
      FlutterBugfender.log('Error initializing deletion sync: $e');
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Widget _getPage(int index) {
    // Return cached page if already loaded
    if (_pagesLoaded[index] && _pages[index] != null) {
      return _pages[index]!;
    }

    // Load page on demand
    Widget page;
    switch (index) {
      case 0:
        page = const Msnotes();
        break;
      case 1:
        page = const ChatAssistantPage();
        break;
      case 2:
        page = const Notetaking();
        break;
      case 3:
        page = const Setting();
        break;
      default:
        page = const Msnotes();
    }

    // Cache the page instance
    _pages[index] = page;
    _pagesLoaded[index] = true;

    return page;
  }

  void _onItemTapped(int index) {
    final controller = _pageController;
    if (controller == null) return;

    final pageDelta = (index - _selectedIndex).abs();
    if (pageDelta > 1) {
      controller.jumpToPage(index);
      return;
    }

    // Optimized animation for better performance
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final bottomInset = media.padding.bottom;
    final bool isCompact = width < 360;
    final double iconSz = isCompact ? 18 : 20;
    final double labelSz = isCompact ? 12 : 13;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        allowImplicitScrolling: false,
        children: List.generate(
          5,
          (index) => RepaintBoundary(
            child: _getPage(index),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: GNav(
          selectedIndex: _selectedIndex,
          onTabChange: _onItemTapped,
          backgroundColor: colorScheme.surface,
          color: colorScheme.onSurface.withOpacity(0.6),
          activeColor: colorScheme.primary,
          tabBackgroundColor: colorScheme.primary.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gap: 8,
          duration: const Duration(milliseconds: 200),
          iconSize: iconSz,
          tabBorderRadius: 12,
          textStyle: theme.textTheme.labelMedium?.copyWith(
            fontSize: labelSz,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            GButton(
              icon: LineIcons.book,
              text: 'Reading',
              iconColor: colorScheme.primary,
            ),
            GButton(
              icon: LineIcons.robot,
              text: 'AI Chat',
              iconColor: colorScheme.primary,
            ),
            GButton(
              icon: LineIcons.edit,
              text: 'Notes',
              iconColor: colorScheme.primary,
            ),
            GButton(
              icon: LineIcons.cog,
              text: 'Settings',
              iconColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
