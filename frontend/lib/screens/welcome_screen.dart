import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Der AppBar bleibt leer, falls du einen Balken möchtest, ansonsten kannst du ihn auch ganz entfernen.
      appBar: AppBar(
        // Entferne den Titel:
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      // Hintergrund über Container setzen:
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ananas.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome to FruitAI!',
                style: TextStyle(
                    fontSize: 28,
                    color: Color.fromARGB(255, 127, 127, 127),
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Snap image / Upload image'),
                onPressed: () {
                  Navigator.pushNamed(context, '/camera');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
