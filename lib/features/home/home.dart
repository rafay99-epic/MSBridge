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

  final List<Widget> _pages = [
    const Msnotes(),
    const ChatAssistantPage(),
    const Notetaking(),
    const Setting(),
  ];

  @override
  void initState() {
    super.initState();

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
      FlutterBugfender.error('Error initializing deletion sync: $e');
      throw Exception('Error initializing deletion sync: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == 0) return;
          if (details.primaryVelocity! > 0) {
            if (_selectedIndex > 0) {
              setState(() {
                _selectedIndex--;
              });
            }
          } else {
            if (_selectedIndex < _pages.length - 1) {
              setState(() {
                _selectedIndex++;
              });
            }
          }
        },
        child: Stack(
          children: _pages.asMap().entries.map((entry) {
            final index = entry.key;
            final page = entry.value;
            return Offstage(
              offstage: _selectedIndex != index,
              child: TickerMode(
                enabled: _selectedIndex == index,
                child: page,
              ),
            );
          }).toList(),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
