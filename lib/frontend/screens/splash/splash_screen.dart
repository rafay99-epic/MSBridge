import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:msbridge/frontend/img/img.dart';
import 'package:msbridge/frontend/screens/auth/login/login.dart';

import 'package:page_transition/page_transition.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntroductionScreen(
      globalBackgroundColor: theme.colorScheme.surface,
      pages: [
        PageViewModel(
          title: "Welcome to MS Bridge",
          body:
              "Seamlessly bridge your MS Notes from web to mobile with MS Bridge – fast, simple, and always in sync",
          image: Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: SvgPicture.asset(
              IntroScreenImage.feature1,
              width: 300,
            ),
          ),
          decoration: PageDecoration(
            pageColor: Theme.of(context).colorScheme.surface,
            imagePadding: EdgeInsets.zero,
            bodyTextStyle: TextStyle(
                fontSize: 18, color: Theme.of(context).colorScheme.primary),
            titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
            bodyPadding: const EdgeInsets.all(16),
          ),
        ),
        PageViewModel(
          title: "Learn at Your Own Pace",
          body:
              "Seamlessly access and sync your MS Notes anytime, anywhere—tailored for your learning needs.",
          image: Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: SvgPicture.asset(
              IntroScreenImage.feature2,
              width: 300,
            ),
          ),
          decoration: PageDecoration(
            pageColor: Theme.of(context).colorScheme.surface,
            imagePadding: EdgeInsets.zero,
            bodyTextStyle: TextStyle(
                fontSize: 18, color: Theme.of(context).colorScheme.primary),
            titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
            bodyPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
      onDone: () {
        Navigator.of(context).push(
          PageTransition(
            child: const LoginScreen(),
            type: PageTransitionType.rightToLeft,
          ),
        );
      },
      onSkip: () {
        Navigator.of(context).push(
          PageTransition(
            child: const LoginScreen(),
            type: PageTransitionType.rightToLeft,
          ),
        );
      },
      showSkipButton: true,
      skip: const Text('Skip'),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        activeSize: const Size(22.0, 10.0),
        activeColor: theme.colorScheme.primary,
        color: theme.colorScheme.secondary.withOpacity(0.5),
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
