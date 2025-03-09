import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:msbridge/utils/img.dart';

class Loading extends StatelessWidget {
  final String message;
  const Loading({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            LoadingScreenImage.loading,
            width: 100,
            height: 100,
            colorFilter: ColorFilter.mode(
              theme.colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.secondary,
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
