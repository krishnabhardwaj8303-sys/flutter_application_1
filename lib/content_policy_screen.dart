import 'package:flutter/material.dart';

class ContentPolicyScreen extends StatelessWidget {
  const ContentPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Text(
          "Content Policy\n\n"
          "Users must not upload or share harmful, abusive, or illegal content on Ajoomi.\n\n"
          "Any misuse of platform, fake bookings, or harassment will lead to account suspension.\n\n"
          "We aim to keep Ajoomi safe for both customers and workers.",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}
