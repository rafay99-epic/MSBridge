import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/frontend/screens/msnotes/msnotes.dart';
import 'package:msbridge/frontend/screens/search/search.dart';
import 'package:msbridge/frontend/screens/setting/setting.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<Home> {
  @override
  void initState() {
    super.initState();
  }

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Msnotes(),
    const Search(),
    const Setting(),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            gap: 5,
            tabs: [
              GButton(
                icon: LineIcons.book,
                text: 'MS Notes',
                iconColor: colorScheme.primary,
              ),
              GButton(
                icon: LineIcons.search,
                text: 'Search',
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
