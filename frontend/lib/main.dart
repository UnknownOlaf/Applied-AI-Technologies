import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/result_screen.dart';

void main() {
  runApp(const FruitAIApp());
}

class FruitAIApp extends StatelessWidget {
  const FruitAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FruitAI Web',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/result': (context) => const ResultScreen(),
      },
    );
  }
}
