import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/msnotes/msnotes.dart';
import 'package:msbridge/features/notes_taking/notetaking.dart';
import 'package:msbridge/features/ai_chat/chat_page.dart';
import 'package:msbridge/features/setting/section/search/search_setting.dart';
import 'package:msbridge/features/voice_notes/screens/voice_notes_screen.dart';
import 'package:msbridge/core/services/delete/deletion_sync_helper.dart';
import 'package:msbridge/core/provider/haptic_feedback_settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _pages = [
    const Msnotes(),
    const ChatAssistantPage(),
    const Notetaking(),
    const VoiceNotesScreen(),
    const Setting(),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start with the first page visible
    _fadeController.forward();

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
      FlutterBugfender.sendCrash("Error initializing deletion sync: $e",
          StackTrace.current.toString());
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // void _onItemTapped(int index) {
  //   if (index != _selectedIndex) {
  //     // Start fade out animation
  //     _fadeController.reverse().then((_) {
  //       setState(() {
  //         _selectedIndex = index;
  //       });
  //       // Start fade in animation
  //       _fadeController.forward();
  //     });
  //   }
  // }

  bool _isTransitioning = false;

  Future<void> _onItemTapped(int index) async {
    if (index == _selectedIndex ||
        _isTransitioning ||
        _fadeController.isAnimating) {
      return;
    }

    // Trigger haptic feedback for navigation
    final hapticProvider =
        Provider.of<HapticFeedbackSettingsProvider>(context, listen: false);
    hapticProvider.triggerNavigationHaptic();

    _isTransitioning = true;
    try {
      await _fadeController.reverse();
      if (!mounted) {
        return;
      }
      setState(() => _selectedIndex = index);
      await _fadeController.forward();
    } finally {
      _isTransitioning = false;
    }
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
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == 0) {
            return;
          }
          int newIndex = _selectedIndex;

          if (details.primaryVelocity! > 0) {
            // Swipe right - go to previous page
            if (_selectedIndex > 0) {
              newIndex = _selectedIndex - 1;
            }
          } else {
            // Swipe left - go to next page
            if (_selectedIndex < _pages.length - 1) {
              newIndex = _selectedIndex + 1;
            }
          }

          // Only animate if we're actually changing pages
          if (newIndex != _selectedIndex) {
            // Trigger haptic feedback for gesture navigation
            final hapticProvider = Provider.of<HapticFeedbackSettingsProvider>(
                context,
                listen: false);
            hapticProvider.triggerGestureHaptic();

            _fadeController.reverse().then((_) {
              setState(() {
                _selectedIndex = newIndex;
              });
              _fadeController.forward();
            });
          }
        },
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _pages[_selectedIndex],
            );
          },
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
              icon: LineIcons.microphone,
              text: 'Voice',
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
