import 'package:flutter/material.dart';

Widget buildTitle(BuildContext context) {
  return Text(
    'AI Note Summary',
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
  );
}
