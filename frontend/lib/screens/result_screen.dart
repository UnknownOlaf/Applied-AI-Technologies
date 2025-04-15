import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Liste für Chat-Nachrichten
  final List<String> messages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hole das Argument (die Beschreibung vom Server) und füge es der Nachrichtenliste hinzu, sofern vorhanden
    final String? newMessage = ModalRoute.of(context)?.settings.arguments as String?;
    if (newMessage != null && newMessage.isNotEmpty) {
      setState(() {
        messages.add(newMessage);
      });
    }
  }

  Widget _buildChatBubble(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ananas.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Chatfenster
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('Noch keine Nachrichten', style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildChatBubble(messages[index]);
                      },
                    ),
            ),
            // Hinweistext (optional, da Senden nicht nötig ist)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Neue Nachrichten werden automatisch hinzugefügt.',
                style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
