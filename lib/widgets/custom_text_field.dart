import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final int numLines;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final bool enableSuggestions;
  final bool autocorrect;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.numLines = 1,
    this.autofillHints,
    this.textInputAction,
    this.enableSuggestions = true,
    this.autocorrect = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLines: numLines,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      style: TextStyle(color: theme.primary),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: theme.primary),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(),
        ),
      ),
    );
  }
}
