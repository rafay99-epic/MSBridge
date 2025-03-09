import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msbridge/widgets/snakbar.dart';

class ContactService {
  final CollectionReference _contactCollection =
      FirebaseFirestore.instance.collection('contactMessages');

  Future<void> saveContactMessage(
      String email, String name, String message, BuildContext context) async {
    try {
      await _contactCollection.add(
        {
          'email': email,
          'name': name,
          'message': message,
        },
      );
      CustomSnackBar.show(
        context,
        'Thank you for the Feedback',
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "Failed to send message: $e",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          content: Text(
            e.toString(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }
}
