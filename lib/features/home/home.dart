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

  final List<Widget> _pages = [
    const Msnotes(),
    const Search(),
    const Notetaking(),
    const ChatAssistantPage(),
    const Setting(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    final controller = _pageController;
    if (controller == null) return;

    // For non-adjacent tabs, jump instantly to avoid animating
    // through heavy intermediate pages which can cause jank.
    final pageDelta = (index - _selectedIndex).abs();
    if (pageDelta > 1) {
      controller.jumpToPage(index);
      return;
    }

    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        allowImplicitScrolling: true,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
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
                icon: LineIcons.pen,
                text: 'Notes',
                iconColor: colorScheme.primary,
              ),
              GButton(
                icon: LineIcons.robot,
                text: 'AI Chat',
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
