import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
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
  bool _showTipCard = false;

  // Analyseergebnis-Daten
  String _fruitType = '';
  String _fruitStatus = '';
  double _freshScore = 0.0;
  double _rottenScore = 0.0;

  // Allgemeine Tipps für alle Obstsorten
final List<String> _generalTips = [
    'Die meisten Früchte bleiben länger frisch, wenn sie im Kühlschrank gelagert werden.',
    'Obst und Gemüse getrennt lagern, da viele Früchte Ethylen abgeben, was Gemüse schneller verderben lässt.',
    'Überreifes Obst eignet sich perfekt für Smoothies oder zum Backen.',
    'Regelmäßige Kontrolle verhindert, dass ein verdorbenes Stück andere Früchte ansteckt.',
    'Viele Früchte können eingefroren werden, um ihre Haltbarkeit zu verlängern.',
    'Äpfel bleiben länger frisch, wenn sie getrennt von anderen Früchten gelagert werden.',
    'Bananen nicht im Kühlschrank lagern! Sie reifen bei Raumtemperatur besser nach.',
    'Orangen halten sich bei Raumtemperatur etwa eine Woche, im Kühlschrank bis zu zwei Wochen.',
    'Erdbeeren erst kurz vor dem Verzehr waschen, um Schimmelbildung zu vermeiden.',
    'Weintrauben im Kühlschrank in einem perforierten Plastikbeutel aufbewahren.',
    'Pfirsiche bei Zimmertemperatur nachreifen lassen und erst dann kühlen.',
    'Kiwis neben Äpfeln oder Bananen legen, um den Reifeprozess zu beschleunigen.',
    'Papier statt Plastik verwenden – viele Früchte atmen, und luftdurchlässige Verpackungen verhindern Schimmelbildung.',
    'Zitrusfrüchte halten länger, wenn sie an einem kühlen, trockenen Ort gelagert werden – nicht im Kühlschrank.',
    'Beeren sollten erst kurz vor dem Verzehr gewaschen werden, um Schimmelbildung zu vermeiden.',
    'Bananen getrennt von anderem Obst lagern – sie beschleunigen den Reifeprozess anderer Früchte.',
    'Äpfel nicht neben empfindlichem Gemüse lagern, da sie besonders viel Ethylen ausstoßen.',
    'Einzelne Druckstellen bei Obst entfernen, damit sich Fäulnis nicht ausbreitet.',
    'Früchte mit essbarer Schale (z. B. Äpfel) vor dem Essen immer gründlich waschen, auch wenn sie bio sind.',
    'Trockenobst ist eine gute Alternative, wenn frisches Obst schnell verdirbt oder nicht verfügbar ist.',
    'Einen reifen Avocado-Kern in einer Schale mit bereits geschnittenem Obst verhindert Braunfärbung.',
  ];

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
          _showTipCard = true;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hole das Argument (die Beschreibung vom Server), falls es nicht über den Konstruktor übergeben wurde
    if (_fruitType.isEmpty) {
      final String? newMessage = ModalRoute.of(context)?.settings.arguments as String?;
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
        String label = jsonData['label'].toString().toLowerCase();
      
        // Erkenne den Fruchttyp basierend auf dem Label
        if (label.contains('apple')) {
          _fruitType = 'Apple';
        } else if (label.contains('banana')) {
          _fruitType = 'Banana';
        } else if (label.contains('orange')) {
          _fruitType = 'Orange';
        } else {
          // Fallback: Entferne Status-Präfixe und formatiere
          if (label.contains('rotten')) {
            _fruitType = label.replaceAll('rotten', '').trim();
          } else if (label.contains('fresh')) {
            _fruitType = label.replaceAll('fresh', '').trim();
          } else {
            _fruitType = label.trim();
          }
        
          // Ersten Buchstaben groß schreiben
          if (_fruitType.isNotEmpty) {
            _fruitType = _fruitType.substring(0, 1).toUpperCase() + 
                       _fruitType.substring(1).toLowerCase();
          }
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
    
      // Debug-Ausgabe
      print('Erkannter Fruchttyp: $_fruitType');
    
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

  // Dynamische Erstellung der Wheel-Daten basierend auf dem aktuellen Obsttyp
  List<WheelData> get _wheels {
    print('Switch case für Fruchttyp: "$_fruitType"'); // Debug-Ausgabe
  
    switch (_fruitType) {
      case 'Apple':
        print('Verwende Apple case'); // Debug
        return [
          WheelData(
            icon: Icons.storage_rounded,
            label: 'Lagern',
            color: Colors.blue,
            title: 'Lagerung von Äpfeln',
            content: 'Optimale Lagerung für Äpfel:\n\n• Temperatur: 0-4°C im Kühlschrank\n• Luftfeuchtigkeit: 90-95%\n• Dunkler, gut belüfteter Ort\n• Getrennt von anderen Früchten lagern\n• Äpfel produzieren Ethylen-Gas\n• In perforierten Plastikbeuteln aufbewahren\n• Beschädigte Äpfel sofort entfernen\n\nRichtig gelagert halten Äpfel bis zu 3 Monate.',
          ),
          WheelData(
            icon: Icons.health_and_safety_rounded,
            label: 'Health',
            color: Colors.green,
            title: 'Gesundheitswerte von Äpfeln',
            content: 'Nährwerte pro 100g Apfel:\n\n• Kalorien: 52 kcal\n• Ballaststoffe: 2,4g (gut für Verdauung)\n• Vitamin C: 5mg (Immunsystem)\n• Kalium: 107mg (Herzgesundheit)\n• Antioxidantien: Quercetin, Catechin\n• Pektin: Senkt Cholesterinspiegel\n• Natürlicher Zucker: 10g\n\n"Ein Apfel am Tag hält den Arzt fern" - alte Weisheit mit wissenschaftlicher Basis!',
          ),
          WheelData(
            icon: Icons.eco_rounded,
            label: 'Umwelt',
            color: Colors.teal,
            title: 'CO2-Fußabdruck von Äpfeln',
            content: 'Umweltauswirkungen von Äpfeln:\n\n• CO2-Fußabdruck: 0,3-0,7 kg CO2/kg\n• Lokale Äpfel: Sehr umweltfreundlich\n• Saisonale Ernte: September-November\n• Wasserbedarf: 700 Liter pro kg\n• Lange Lagerbarkeit reduziert Verschwendung\n• Deutsche Apfelproduktion sehr nachhaltig\n• Biologischer Anbau ohne Pestizide möglich\n\nRegionale Äpfel sind eine der umweltfreundlichsten Früchte!',
          ),
          WheelData(
            icon: Icons.restaurant_rounded,
            label: 'Rezepte',
            color: Colors.orange,
            title: 'Leckere Apfel-Rezepte',
            content: 'Kreative Apfel-Verwendung:\n\n• Klassischer Apfelkuchen\n• Apfelmus (auch für Babys)\n• Bratäpfel mit Zimt und Nüssen\n• Apfel-Crumble mit Haferflocken\n• Getrocknete Apfelringe als Snack\n• Apfel-Smoothie mit Ingwer\n• Apfelchips im Ofen gebacken\n• Apfel-Zimt-Muffins\n\nÜberreife Äpfel eignen sich perfekt für Kompott und Kuchen!',
          ),
          WheelData(
            icon: Icons.history_rounded,
            label: 'History',
            color: Colors.purple,
            title: 'Analyse Historie',
            content: 'Ihre bisherigen Apfel-Analysen:\n\n• 12.05.2025: Frisch (93%)\n• 18.05.2025: Frisch (87%)\n• 25.05.2025: Verdorben (28%)\n• 02.06.2025: Frisch (91%)\n\nDurchschnittliche Haltbarkeit: 10-14 Tage\n\nTipp: Äpfel getrennt lagern, da sie Ethylen produzieren.',          ),
        ];
    
      case 'Banana':
        print('Verwende Banana case'); // Debug
        return [
          WheelData(
            icon: Icons.storage_rounded,
            label: 'Lagern',
            color: Colors.blue,
            title: 'Lagerung von Bananen',
            content: 'Optimale Lagerung für Bananen:\n\n• Temperatur: 12-15°C (Raumtemperatur)\n• NIEMALS im Kühlschrank lagern!\n• Hängende Lagerung verlängert Haltbarkeit\n• Getrennt von anderen Früchten\n• Grüne Bananen bei Zimmertemperatur nachreifen\n• Reife Bananen: 2-3 Tage haltbar\n• Braune Stellen sind normal und süß\n\nBananen reifen nach der Ernte weiter - perfekt für gestaffelte Reife!',
          ),
          WheelData(
            icon: Icons.health_and_safety_rounded,
            label: 'Health',
            color: Colors.green,
            title: 'Gesundheitswerte von Bananen',
            content: 'Nährwerte pro 100g Banane:\n\n• Kalorien: 89 kcal\n• Kalium: 358mg (Muskel- und Herzfunktion)\n• Vitamin B6: 0,4mg (Nervensystem)\n• Vitamin C: 9mg (Immunsystem)\n• Ballaststoffe: 2,6g (Verdauung)\n• Magnesium: 27mg (Knochen und Muskeln)\n• Natürlicher Zucker: 12g (schnelle Energie)\n\nPerfekt für Sportler - natürliche Energie und Elektrolyte!',
          ),
          WheelData(
            icon: Icons.eco_rounded,
            label: 'Umwelt',
            color: Colors.teal,
            title: 'CO2-Fußabdruck von Bananen',
            content: 'Umweltauswirkungen von Bananen:\n\n• CO2-Fußabdruck: 0,7-0,9 kg CO2/kg\n• Langer Transportweg aus Tropen\n• Wasserbedarf: 790 Liter pro kg\n• Fairer Handel unterstützt Bauern\n• Biologischer Anbau ohne Pestizide\n• Bananenschalen kompostierbar\n• Nachhaltige Plantagen möglich\n\nFair-Trade und Bio-Bananen für bessere Umweltbilanz wählen!',
          ),
          WheelData(
            icon: Icons.restaurant_rounded,
            label: 'Rezepte',
            color: Colors.orange,
            title: 'Leckere Bananen-Rezepte',
            content: 'Kreative Bananen-Verwendung:\n\n• Bananenbrot (perfekt für überreife Bananen)\n• Bananen-Smoothie mit Haferflocken\n• Gebackene Bananen mit Honig\n• Bananen-Pancakes ohne Mehl\n• Gefrorene Bananen als Eis-Ersatz\n• Bananen-Muffins mit Nüssen\n• Bananen-Milchshake\n• Bananen-Chips getrocknet\n\nÜberreife Bananen sind am süßesten für Backrezepte!',
          ),
          WheelData(
            icon: Icons.history_rounded,
            label: 'History',
            color: Colors.purple,
            title: 'Analyse Historie',
            content: 'Ihre bisherigen Bananen-Analysen:\n\n• 10.05.2025: Frisch (95%)\n• 13.05.2025: Frisch (82%)\n• 15.05.2025: Verdorben (31%)\n• 01.06.2025: Frisch (89%)\n\nDurchschnittliche Haltbarkeit: 4-6 Tage\n\nTipp: Bananen niemals im Kühlschrank lagern!',          ),
        ];
    
      case 'Orange':
        print('Verwende Orange case'); // Debug
        return [
          WheelData(
            icon: Icons.storage_rounded,
            label: 'Lagern',
            color: Colors.blue,
            title: 'Lagerung von Orangen',
            content: 'Optimale Lagerung für Orangen:\n\n• Temperatur: 4-8°C im Kühlschrank\n• Bei Raumtemperatur: 1 Woche haltbar\n• Im Kühlschrank: bis zu 2 Wochen\n• Luftfeuchtigkeit: 85-90%\n• Nicht in Plastikbeuteln lagern\n• Vor Verzehr auf Zimmertemperatur bringen\n• Beschädigte Orangen sofort entfernen\n\nOrangen verlieren bei Kälte etwas Aroma, gewinnen aber Haltbarkeit!',
          ),
          WheelData(
            icon: Icons.health_and_safety_rounded,
            label: 'Health',
            color: Colors.green,
            title: 'Gesundheitswerte von Orangen',
            content: 'Nährwerte pro 100g Orange:\n\n• Kalorien: 47 kcal\n• Vitamin C: 53mg (59% Tagesbedarf!)\n• Folsäure: 40μg (Zellbildung)\n• Kalium: 181mg (Blutdruck)\n• Ballaststoffe: 2,4g (Verdauung)\n• Antioxidantien: Flavonoide, Carotinoide\n• Natürlicher Zucker: 9g\n\nEine Orange deckt mehr als die Hälfte des täglichen Vitamin C-Bedarfs!',
          ),
          WheelData(
            icon: Icons.eco_rounded,
            label: 'Umwelt',
            color: Colors.teal,
            title: 'CO2-Fußabdruck von Orangen',
            content: 'Umweltauswirkungen von Orangen:\n\n• CO2-Fußabdruck: 0,3-0,7 kg CO2/kg\n• Hauptanbaugebiete: Spanien, Italien\n• Wasserbedarf: 560 Liter pro kg\n• Saisonale Ernte: November-April\n• Kurze Transportwege aus Südeuropa\n• Biologischer Anbau weit verbreitet\n• Orangenschalen kompostierbar\n\nEuropäische Orangen haben eine gute Umweltbilanz!',
          ),
          WheelData(
            icon: Icons.restaurant_rounded,
            label: 'Rezepte',
            color: Colors.orange,
            title: 'Leckere Orangen-Rezepte',
            content: 'Kreative Orangen-Verwendung:\n\n• Frisch gepresster Orangensaft\n• Orangen-Marmelade hausgemacht\n• Orangenkuchen mit Glasur\n• Orangen-Smoothie mit Karotten\n• Kandierte Orangenschalen\n• Orangen-Vinaigrette für Salate\n• Orangen-Sorbet als Dessert\n• Orangen-Muffins mit Schokolade\n\nOrangenschalen nicht wegwerfen - perfekt für Tee und Backrezepte!',
          ),
          WheelData(
            icon: Icons.history_rounded,
            label: 'History',
            color: Colors.purple,
            title: 'Analyse Historie',
            content: 'Ihre bisherigen Orangen-Analysen:\n\n• 08.05.2025: Frisch (96%)\n• 15.05.2025: Frisch (88%)\n• 22.05.2025: Verdorben (35%)\n• 29.05.2025: Frisch (92%)\n\nDurchschnittliche Haltbarkeit: 7-10 Tage\n\nTipp: Orangen vor dem Auspressen rollen für mehr Saft.',          ),
        ];
    
      default:
        print('Verwende default case für: "$_fruitType"'); // Debug
        return [
          WheelData(
            icon: Icons.storage_rounded,
            label: 'Lagern',
            color: Colors.blue,
            title: 'Lagerung von ${_fruitType.isNotEmpty ? _fruitType : "Obst"}',
            content: 'Optimale Lagerungsbedingungen:\n\n• Temperatur: 4-8°C\n• Luftfeuchtigkeit: 85-90%\n• Dunkler, gut belüfteter Ort\n• Getrennt von anderen Früchten\n• Regelmäßige Kontrolle auf Verderb\n\nBei richtiger Lagerung bleibt das Obst länger frisch und behält seine Nährstoffe.',
          ),
          WheelData(
            icon: Icons.health_and_safety_rounded,
            label: 'Health',
            color: Colors.green,
            title: 'Gesundheitswerte',
            content: 'Nährwerte und Vitamine:\n\n• Vitamin C: Stärkt das Immunsystem\n• Ballaststoffe: Fördern die Verdauung\n• Antioxidantien: Schützen vor freien Radikalen\n• Kalium: Wichtig für Herz und Muskeln\n• Natürlicher Fruchtzucker: Schnelle Energie\n\nFrisches Obst ist ein wichtiger Bestandteil einer ausgewogenen Ernährung.',
          ),
          WheelData(
            icon: Icons.eco_rounded,
            label: 'Umwelt',
            color: Colors.teal,
            title: 'CO2-Fußabdruck',
            content: 'Umweltauswirkungen:\n\n• Lokale Produkte reduzieren Transport-CO2\n• Saisonales Obst ist umweltfreundlicher\n• Weniger Verpackung = weniger Müll\n• Kompostierung von Obstabfällen\n• Unterstützung nachhaltiger Landwirtschaft\n\nBewusste Entscheidungen helfen unserer Umwelt.',
          ),
          WheelData(
            icon: Icons.restaurant_rounded,
            label: 'Rezepte',
            color: Colors.orange,
            title: 'Leckere Rezeptideen',
            content: 'Kreative Verwendung:\n\n• Fruchtsalat mit Joghurt\n• Smoothies und Säfte\n• Obstkuchen und Muffins\n• Marmelade und Konfitüre\n• Getrocknete Früchte als Snack\n• Frucht-Eis am Stiel\n\nAuch leicht überreifes Obst kann noch köstlich verarbeitet werden!',
          ),
          WheelData(
            icon: Icons.history_rounded,
            label: 'History',
            color: Colors.purple,
            title: 'Analyse Historie',
            content: 'Ihre bisherigen Analysen:\n\n• Verfolgen Sie Ihre Obst-Analysen\n• Erkennen Sie Muster in der Qualität\n• Verbessern Sie Ihre Einkaufsgewohnheiten\n• Reduzieren Sie Lebensmittelverschwendung\n• Optimieren Sie Ihre Lagerung\n\nDie Historie hilft Ihnen, bessere Entscheidungen zu treffen.',          ),
        ];
    }
  }

  // Holt einen zufälligen Tipp aus den allgemeinen Tipps
  String get _currentTip {
    final random = math.Random();
    return _generalTips[random.nextInt(_generalTips.length)];
  }

  void _showInfoModal(String title, String content, IconData icon, Color color) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Action Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Verstanden',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                  ),
                  child: Column(
                    children: [
                      // Hero logo
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 20),
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
                      
                      // Ergebnisanzeige
                      _isLoading
                          ? Container(
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
                            )
                          : _fruitType.isEmpty
                              ? Container(
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
                                )
                              : _buildResultCard(isSmallScreen),
                      
                      const SizedBox(height: 20),
                      
                      // Frische-Meter
                      if (_fruitType.isNotEmpty)
                        _buildFrischeMeter(isSmallScreen),
                      
                      if (_fruitType.isNotEmpty)
                        const SizedBox(height: 20),
                      
                      // Tipp des Tages
                      if (_showTipCard && _fruitType.isNotEmpty)
                        AnimatedOpacity(
                          opacity: _showTipCard ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: _buildTipCard(isSmallScreen),
                        ),
                      
                      if (_showTipCard && _fruitType.isNotEmpty)
                        const SizedBox(height: 20),
                      
                      // Neues Bild Button
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
                      
                      const SizedBox(height: 20),
                      
                      // Action Wheels
                      ActionWheels(
                        wheels: _wheels,
                        onWheelTap: _showInfoModal,
                      ),
                      
                      // Zusätzlicher Abstand am Ende
                      const SizedBox(height: 20),
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
              color: _fruitStatus.toLowerCase() == 'frisch'
                  ? Colors.green.shade50
                  : _fruitStatus.toLowerCase() == 'verdorben'
                      ? Colors.red
                      : Colors.green.shade50,
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
                    color: _fruitStatus.toLowerCase() == 'frisch'
                        ? Colors.green
                        : _fruitStatus.toLowerCase() == 'verdorben'
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Analyse Ergebnis',
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
                  value: _fruitType == 'Apple' ? 'Apfel' : 
                         _fruitType == 'Banana' ? 'Banane' :
                         _fruitType == 'Orange' ? 'Orange' : _fruitType,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrischeMeter(bool isSmallScreen) {
    // Berechne die Position des Indikators basierend auf dem Frische-Score
    // Wenn der Frische-Score hoch ist, ist das Obst frisch (rechts)
    // Wenn der Rotten-Score hoch ist, ist das Obst verdorben (links)
    final indicatorPosition = _freshScore;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Frische-Meter und Verdorben-Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verdorben',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const Text(
                'Frische-Meter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Frisch',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Frische-Meter Skala
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Farbverlauf-Balken
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.lightGreen,
                      Colors.green,
                    ],
                  ),
                ),
              ),
              
              // Indikator-Punkt
              Positioned(
                left: (indicatorPosition.clamp(0.0, 1.0) * (MediaQuery.of(context).size.width - 112)) + 16,
                top: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: indicatorPosition > 0.5 ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.amber.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber.shade600,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tipp des Tages',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _currentTip,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                height: 1.4,
                color: Colors.black87,
              ),
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

// Action Wheels Widget
class ActionWheels extends StatefulWidget {
  final List<WheelData> wheels;
  final Function(String title, String content, IconData icon, Color color) onWheelTap;

  const ActionWheels({
    Key? key, 
    required this.wheels,
    required this.onWheelTap,
  }) : super(key: key);

  @override
  State<ActionWheels> createState() => _ActionWheelsState();
}

class _ActionWheelsState extends State<ActionWheels>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              // Wheels
              ...List.generate(widget.wheels.length, (index) {
                final angle = (2 * math.pi / widget.wheels.length) * index;
                final radius = 70.0;
                final x = radius * math.cos(angle);
                final y = radius * math.sin(angle);

                return Transform.translate(
                  offset: Offset(x, y),
                  child: ActionWheel(
                    data: widget.wheels[index],
                    isHovered: _hoveredIndex == index,
                    onHover: (isHovered) {
                      setState(() {
                        _hoveredIndex = isHovered ? index : -1;
                      });
                    },
                    onTap: () {
                      widget.onWheelTap(
                        widget.wheels[index].title,
                        widget.wheels[index].content,
                        widget.wheels[index].icon,
                        widget.wheels[index].color,
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// Individual Action Wheel
class ActionWheel extends StatefulWidget {
  final WheelData data;
  final bool isHovered;
  final Function(bool) onHover;
  final VoidCallback onTap;

  const ActionWheel({
    Key? key,
    required this.data,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ActionWheel> createState() => _ActionWheelState();
}

class _ActionWheelState extends State<ActionWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(ActionWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered != oldWidget.isHovered) {
      if (widget.isHovered) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.data.color,
                        boxShadow: [
                          BoxShadow(
                            color: widget.data.color.withOpacity(0.4),
                            blurRadius: widget.isHovered ? 15 : 8,
                            spreadRadius: widget.isHovered ? 3 : 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.data.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isHovered 
                            ? widget.data.color 
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Data class for wheel information
class WheelData {
  final IconData icon;
  final String label;
  final Color color;
  final String title;
  final String content;

  WheelData({
    required this.icon,
    required this.label,
    required this.color,
    required this.title,
    required this.content,
  });
}
