import 'package:flutter/material.dart';

import '../config/app_colors.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GreenGrid')),
      body: const Center(
        child: Text(
          'Home Screen - da implementare',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aggiungi zona — implementazione nello Step 6')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
