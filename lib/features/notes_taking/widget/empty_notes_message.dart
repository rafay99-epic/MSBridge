import 'package:flutter/material.dart';

class EmptyNotesMessage extends StatelessWidget {
  const EmptyNotesMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("No notes yet!"));
  }
}
