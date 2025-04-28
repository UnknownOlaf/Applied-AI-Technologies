import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../widgets/animated_text.dart';
import '../widgets/bounce_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20.0 : 40.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Logo Animation
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: Hero(
                          tag: 'logo',
                          child: Container(
                            width: isSmallScreen ? 120 : 150,
                            height: isSmallScreen ? 120 : 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.eco_rounded,
                                size: isSmallScreen ? 70 : 90,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Title Animation
                      const AnimatedText(
                        text: 'Welcome to FruitAI',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        delay: 300,
                      ),
                      const SizedBox(height: 20),
                      // Description Animation
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          // Sicherstellen, dass der Wert zwischen 0.0 und 1.0 liegt
                          final opacity = _controller.value > 0.4
                              ? (_controller.value - 0.4) * 1.67
                              : 0.0;
                          return Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            'FruitAI erkennt mit Hilfe künstlicher Intelligenz, '
                            'ob dein Obst frisch oder verdorben ist.\n\n'
                            'Drücke auf den Button unten, um ein Bild aufzunehmen oder hochzuladen.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Button Animation
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          // Sicherstellen, dass der Wert zwischen 0.0 und 1.0 liegt
                          final opacity = _controller.value > 0.6
                              ? (_controller.value - 0.6) * 2.5
                              : 0.0;
                          return Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: child,
                          );
                        },
                        child: BounceButton(
                          onTap: () {
                            Navigator.pushNamed(context, '/camera');
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: isSmallScreen ? 25 : 40,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withGreen(180),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                Text(
                                  'Bild aufnehmen',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
