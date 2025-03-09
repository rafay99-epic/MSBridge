import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:msbridge/features/auth/login/login.dart';

import 'package:msbridge/utils/img.dart';
import 'package:page_transition/page_transition.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  final List<Map<String, dynamic>> _pages = [
    {
      'title': "Welcome to MS Bridge",
      'body':
          "Seamlessly bridge your MS Notes from web to mobile with MS Bridge – fast, simple, and always in sync",
      'image': IntroScreenImage.feature1,
    },
    {
      'title': "Learn at Your Own Pace",
      'body':
          "Seamlessly access and sync your MS Notes anytime, anywhere—tailored for your learning needs.",
      'image': IntroScreenImage.feature2,
    },
    {
      'title': "Collaborate with Ease",
      'body':
          "Share your MS Notes with colleagues and friends for seamless teamwork.",
      'image': IntroScreenImage.feature3,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      PageTransition(
        child: const LoginScreen(),
        type: PageTransitionType.leftToRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.5)).clamp(0.0, 1.0);
                      }
                      return Transform.scale(
                        scale: Curves.easeInOut.transform(value),
                        child: Opacity(
                          opacity: value,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 50.0),
                                  child: SvgPicture.asset(
                                    page['image'],
                                    width: 300,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  page['title'],
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  page['body'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: const Text('Skip'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicator(theme),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      } else {
                        _navigateToLogin();
                      }
                    },
                    child: Text(
                        _currentPage == _pages.length - 1 ? 'Done' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageIndicator(ThemeData theme) {
    List<Widget> list = [];
    for (int i = 0; i < _pages.length; i++) {
      list.add(i == _currentPage
          ? _indicator(true, theme)
          : _indicator(false, theme));
    }
    return list;
  }

  Widget _indicator(bool isActive, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      height: 10.0,
      width: isActive ? 22.0 : 10.0,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary.withOpacity(0.5),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: isActive
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : null,
      ),
    );
  }
}
