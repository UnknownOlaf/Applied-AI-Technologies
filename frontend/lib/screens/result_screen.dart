import 'package:flutter/material.dart';
import 'dart:convert';
import '../widgets/animated_background.dart';
import '../widgets/bounce_button.dart';

class ResultScreen extends StatefulWidget {
  final String? message;

  const ResultScreen({Key? key, this.message}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isLoading = true;

  // Analyseergebnis-Daten
  String _fruitType = '';
  String _fruitStatus = '';
  double _freshScore = 0.0;
  double _rottenScore = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    // Verarbeite die Nachricht, wenn vorhanden
    if (widget.message != null && widget.message!.isNotEmpty) {
      _processMessage(widget.message!);
    }

    // Kurze Verzögerung für Animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hole das Argument (die Beschreibung vom Server), falls es nicht über den Konstruktor übergeben wurde
    if (_fruitType.isEmpty) {
      final String? newMessage =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (newMessage != null && newMessage.isNotEmpty) {
        _processMessage(newMessage);
      }
    }
  }

  void _processMessage(String message) {
    try {
      // Versuche, die Nachricht als JSON zu parsen
      final jsonData = jsonDecode(message);

      // Extrahiere den Obsttyp aus dem Label
      if (jsonData['label'] != null) {
        String label = jsonData['label'].toString();

        // Entferne Status-Präfixe wie "rotten" oder "fresh" vom Label
        if (label.contains('rotten')) {
          _fruitType = label.replaceAll('rotten', '');
        } else if (label.contains('fresh')) {
          _fruitType = label.replaceAll('fresh', '');
        } else {
          _fruitType = label;
        }

        // Ersten Buchstaben groß schreiben und Rest in Kleinbuchstaben
        if (_fruitType.isNotEmpty) {
          _fruitType = _fruitType.substring(0, 1).toUpperCase() +
              _fruitType.substring(1).toLowerCase();
        }
      }

      // Extrahiere den Status
      if (jsonData['category'] != null) {
        String category = jsonData['category'].toString();
        if (category == 'fresh') {
          _fruitStatus = 'Frisch';
        } else if (category == 'rotten') {
          _fruitStatus = 'Verdorben';
        } else {
          _fruitStatus = category;
          // Ersten Buchstaben groß schreiben
          _fruitStatus = _fruitStatus.substring(0, 1).toUpperCase() +
              _fruitStatus.substring(1).toLowerCase();
        }
      }

      // Extrahiere die Wahrscheinlichkeitswerte
      if (jsonData['score'] != null && jsonData['score'] is Map) {
        final score = jsonData['score'] as Map;
        if (score['fresh'] != null) {
          _freshScore = double.tryParse(score['fresh'].toString()) ?? 0.0;
        }
        if (score['rotten'] != null) {
          _rottenScore = double.tryParse(score['rotten'].toString()) ?? 0.0;
        }
      }
    } catch (e) {
      // Fehler beim Parsen des JSON
      _fruitType = 'Unbekannt';
      _fruitStatus = 'Unbekannt';
      print('Fehler beim Parsen der Nachricht: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ergebnis'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Column(
                children: [
                  // Hero logo
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Hero(
                      tag: 'logo',
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.eco_rounded,
                            size: 35,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ergebnisanzeige
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Analysiere Obst...',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 18 : 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _fruitType.isEmpty
                            ? Center(
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 24,
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 50,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Keine Analyseergebnisse',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 18 : 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Bitte nimm ein Bild auf oder wähle ein Bild aus, um es zu analysieren.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 24,
                                  vertical: 16,
                                ),
                                child: _buildResultCard(isSmallScreen),
                              ),
                  ),
                  // Bottom actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        BounceButton(
                          onTap: () {
                            Navigator.pushNamed(context, '/camera');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
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
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Neues Bild',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Analyse-Ergebnis',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Obsttyp
                _buildInfoRow(
                  icon: Icons.category_rounded,
                  label: 'Obsttyp:',
                  value: _fruitType,
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 20),

                // Status
                _buildInfoRow(
                  icon: _getStatusIcon(),
                  label: 'Status:',
                  value: _fruitStatus,
                  valueColor: _getStatusColor(),
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 20),

                // Wahrscheinlichkeit
                Text(
                  'Wahrscheinlichkeit:',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 10),

                // Frisch-Score
                _buildScoreBar(
                  label: 'Frisch',
                  score: _freshScore,
                  color: Colors.green,
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 8),

                // Verdorben-Score
                _buildScoreBar(
                  label: 'Verdorben',
                  score: _rottenScore,
                  color: Colors.red,
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isSmallScreen,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: isSmallScreen ? 24 : 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBar({
    required String label,
    required double score,
    required Color color,
    required bool isSmallScreen,
  }) {
    // Konvertiere Score in Prozent für die Anzeige
    final percent = (score * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (_fruitStatus.toLowerCase()) {
      case 'frisch':
        return Icons.check_circle_rounded;
      case 'verdorben':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getStatusColor() {
    switch (_fruitStatus.toLowerCase()) {
      case 'frisch':
        return Colors.green;
      case 'verdorben':
        return Colors.red;
      default:
        return Colors.grey.shade700;
    }
  }
}
