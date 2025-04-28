import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/result_screen.dart';
import 'utils/theme.dart';
import 'utils/page_transition.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const FruitAIApp());
}

class FruitAIApp extends StatelessWidget {
  const FruitAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FruitAI Web',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return PageTransition(child: const WelcomeScreen());
          case '/camera':
            return PageTransition(child: const CameraScreen());
          case '/result':
            return PageTransition(
              child: ResultScreen(message: settings.arguments as String?),
            );
          default:
            return null;
        }
      },
    );
  }
}
