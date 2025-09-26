import 'package:flutter/material.dart';

/// Home screen with swipe interface for movie recommendations
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Recommendations'),
      ),
      body: const Center(
        child: Text(
          'Home Screen - Swipe Interface\n(To be implemented)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}