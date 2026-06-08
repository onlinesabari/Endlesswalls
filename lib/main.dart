import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const EndlessWallsApp());
}

class EndlessWallsApp extends StatelessWidget {
  const EndlessWallsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EndlessWalls',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const HomeScreen(),
    );
  }
}