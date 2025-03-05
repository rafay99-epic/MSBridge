import 'package:flutter/material.dart';
import 'package:msbridge/frontend/screens/msnotes/msnotes.dart';
import 'package:msbridge/frontend/widgets/snakbar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/frontend/screens/search/search.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  OfflineScreenState createState() => OfflineScreenState();
}

class OfflineScreenState extends State<OfflineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomSnackBar.show(context, "You're in Offline Mode 📴");
    });
  }

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Msnotes(),
    const Search(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: _pages[_selectedIndex],
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
            gap: 0,
            tabs: [
              GButton(
                icon: LineIcons.book,
                text: 'MS Notes',
                iconColor: colorScheme.primary,
                semanticLabel: 'MS Notes',
                haptic: true,
              ),
              GButton(
                icon: LineIcons.search,
                text: 'Search',
                iconColor: colorScheme.primary,
                haptic: true,
                semanticLabel: 'Search',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
