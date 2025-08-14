import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/msnotes/msnotes.dart';
import 'package:msbridge/features/search/search.dart';
import 'package:msbridge/features/notes_taking/notetaking.dart';
import 'package:msbridge/features/ai_chat/chat_page.dart';
import 'package:msbridge/features/setting/pages/setting.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  PageController? _pageController;

  // Lazy loading for pages
  final List<Widget?> _pages = List.filled(5, null);
  final List<bool> _pagesLoaded = List.filled(5, false);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // Pre-load the first page
    _pagesLoaded[0] = true;
    _pages[0] = const Msnotes();
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
        page = const Search();
        break;
      case 2:
        page = const ChatAssistantPage();
        break;
      case 3:
        page = const Notetaking();
        break;
      case 4:
        page = const Setting();
        break;
      default:
        page = const Msnotes();
    }

    // Cache the page
    _pages[index] = page;
    _pagesLoaded[index] = true;

    return page;
  }

  void _onItemTapped(int index) {
    final controller = _pageController;
    if (controller == null) return;

    // Pre-load the target page to reduce lag
    if (!_pagesLoaded[index]) {
      _getPage(index);
    }

    // For non-adjacent tabs, jump instantly to avoid animating
    // through heavy intermediate pages which can cause jank.
    final pageDelta = (index - _selectedIndex).abs();
    if (pageDelta > 1) {
      controller.jumpToPage(index);
      return;
    }

    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 200), // Reduced duration
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Pre-load adjacent pages for smoother navigation
    if (index > 0 && !_pagesLoaded[index - 1]) {
      _getPage(index - 1);
    }
    if (index < _pages.length - 1 && !_pagesLoaded[index + 1]) {
      _getPage(index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        allowImplicitScrolling:
            false, // Disabled to prevent unnecessary loading
        children: List.generate(5, (index) => _getPage(index)),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GNav(
            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,
            backgroundColor: colorScheme.surface,
            color: colorScheme.onSurface,
            activeColor: colorScheme.primary,
            tabBackgroundColor: colorScheme.primary.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            gap: 4,
            duration: const Duration(milliseconds: 200), // Reduced duration
            tabs: [
              GButton(
                icon: LineIcons.book,
                text: 'Reading',
                iconColor: colorScheme.primary,
              ),
              GButton(
                icon: LineIcons.search,
                text: 'Search',
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
      ),
    );
  }
}
