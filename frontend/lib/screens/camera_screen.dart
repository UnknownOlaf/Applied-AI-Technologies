import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../widgets/animated_background.dart';
import '../widgets/loading_animation.dart';
import '../widgets/bounce_button.dart';

import 'dart:html' as html;
import 'dart:ui' as ui;

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  XFile? _image;
  bool _isLoading = false;
  String _error = '';

  html.VideoElement? _webcamVideo;
  html.CanvasElement? _canvas;
  html.CanvasRenderingContext2D? _canvasContext;
  Uint8List? _capturedWebImage;

  bool _showWebcam = false;
  bool _showConfirmButton = false;
  bool _isCapturing = false; // Neuer Status für die Aufnahme-Animation

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

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
  }

  @override
  void dispose() {
    _stopWebcam(); // Webcam beim Verlassen der Seite stoppen
    _animationController.dispose();
    super.dispose();
  }

  void _initializeWebCamera() {
    _webcamVideo = html.VideoElement()
      ..style.width = '100%'
      ..autoplay = true;

    html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true}).then((stream) {
      _webcamVideo!.srcObject = stream;
    });

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'webcamElement',
      (int viewId) => _webcamVideo!,
    );
  }

  void _startWebcam() {
    setState(() {
      _showWebcam = true;
      _capturedWebImage = null;
      _showConfirmButton = false;
    });
    _initializeWebCamera();
  }

  // Methode zum Stoppen der Webcam
  void _stopWebcam() {
    if (_webcamVideo != null && _webcamVideo!.srcObject != null) {
      // Alle Tracks des Streams stoppen
      final mediaStream = _webcamVideo!.srcObject as html.MediaStream;
      final tracks = mediaStream.getTracks();
      for (final track in tracks) {
        track.stop();
      }
      _webcamVideo!.srcObject = null;
    }
  }

  void _captureWebcamImage() {
    // Animation für die Aufnahme starten
    setState(() {
      _isCapturing = true;
    });

    // Kurze Verzögerung für den Blitz-Effekt
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_webcamVideo != null) {
        _canvas = html.CanvasElement(
            width: _webcamVideo!.videoWidth, height: _webcamVideo!.videoHeight);
        _canvasContext =
            _canvas!.getContext('2d') as html.CanvasRenderingContext2D;
        _canvasContext!.drawImage(_webcamVideo!, 0, 0);

        _canvas!.toBlob().then((blob) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(blob);
          reader.onLoadEnd.listen((event) {
            // Webcam stoppen nach der Aufnahme
            _stopWebcam();

            setState(() {
              _capturedWebImage = reader.result as Uint8List;
              _showConfirmButton = true;
              _showWebcam = false; // Webcam-Anzeige ausblenden
              _isCapturing = false; // Animation beenden
            });
          });
        });
      }
    });
  }

  void _confirmCapturedImage() {
    setState(() {
      _showWebcam = false;
      _showConfirmButton = false;
    });
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();

      if (kIsWeb && source == ImageSource.camera) {
        setState(() {
          _error = 'Kamera-Zugriff ist im Browser nicht möglich.';
        });
        return;
      }

      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
          _capturedWebImage = null;
          _error = '';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Aufnehmen oder Auswählen des Bildes: $e';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null && _capturedWebImage == null) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final uri = Uri.parse('http://localhost:8000/predict');
      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        if (_capturedWebImage != null) {
          final multipartFile = http.MultipartFile.fromBytes(
            'file',
            _capturedWebImage!,
            filename: 'captured.png',
          );
          request.files.add(multipartFile);
        } else if (_image != null) {
          final bytes = await _image!.readAsBytes();
          final multipartFile = http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: _image!.name,
          );
          request.files.add(multipartFile);
        } else {
          setState(() {
            _error = 'Kein Bild zum Hochladen vorhanden.';
          });
          return;
        }
      } else {
        final multipartFile =
            await http.MultipartFile.fromPath('file', _image!.path);
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final description = response.body;
        // ignore: use_build_context_synchronously
        Navigator.pushNamed(context, '/result', arguments: description);
      } else {
        setState(() {
          _error = 'Fehler beim Hochladen: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Hochladen: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bild aufnehmen'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hero logo
                      Hero(
                        tag: 'logo',
                        child: Container(
                          width: 80,
                          height: 80,
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
                              size: 50,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Image preview container
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: 500,
                          minHeight: isSmallScreen ? 250 : 300,
                        ),
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
                        child: _isCapturing
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              )
                            : _buildImagePreview(isSmallScreen),
                      ),
                      const SizedBox(height: 20),
                      // Error message
                      if (_error.isNotEmpty)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Action buttons
                      Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            Text(
                              'Wähle eine Option',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 15,
                              runSpacing: 15,
                              alignment: WrapAlignment.center,
                              children: [
                                if (kIsWeb)
                                  _buildActionButton(
                                    icon: _showWebcam
                                        ? Icons.camera_alt_rounded
                                        : Icons.videocam_rounded,
                                    label: _showWebcam
                                        ? "Webcam schließen"
                                        : "Webcam öffnen",
                                    onTap: _showWebcam
                                        ? () {
                                            _stopWebcam();
                                            setState(() {
                                              _showWebcam = false;
                                            });
                                          }
                                        : _startWebcam,
                                    isSmallScreen: isSmallScreen,
                                  )
                                else
                                  _buildActionButton(
                                    icon: Icons.camera_alt_rounded,
                                    label: "Kamera öffnen",
                                    onTap: () => _getImage(ImageSource.camera),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                _buildActionButton(
                                  icon: Icons.photo_library_rounded,
                                  label: "Galerie öffnen",
                                  onTap: () => _getImage(ImageSource.gallery),
                                  isSmallScreen: isSmallScreen,
                                ),
                                _buildActionButton(
                                  icon: Icons.upload_rounded,
                                  label: "Bild hochladen",
                                  onTap: _uploadImage,
                                  isLoading: _isLoading,
                                  isSmallScreen: isSmallScreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildImagePreview(bool isSmallScreen) {
    if (kIsWeb && _showWebcam) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Live Webcam',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: isSmallScreen ? 200 : 250,
            width: double.infinity,
            child: HtmlElementView(viewType: 'webcamElement'),
          ),
          const SizedBox(height: 10),
          BounceButton(
            onTap: _captureWebcamImage,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Foto aufnehmen',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      );
    }

    if (kIsWeb && _capturedWebImage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Aufgenommenes Foto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Image.memory(
              _capturedWebImage!,
              height: isSmallScreen ? 200 : 250,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          if (_showConfirmButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BounceButton(
                  onTap: _confirmCapturedImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Bild übernehmen',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                BounceButton(
                  onTap: _startWebcam,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Neu aufnehmen',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
        ],
      );
    }

    if (kIsWeb && _image != null && _capturedWebImage == null) {
      return FutureBuilder<Uint8List>(
        future: _image!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: Image.memory(
                snapshot.data!,
                height: isSmallScreen ? 200 : 250,
                fit: BoxFit.contain,
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Fehler beim Laden des Bildes",
                style: TextStyle(color: Colors.red),
              ),
            );
          } else {
            return const Center(child: LoadingAnimation());
          }
        },
      );
    }

    if (!kIsWeb && _image != null) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        child: Image.file(
          File(_image!.path),
          height: isSmallScreen ? 200 : 250,
          fit: BoxFit.contain,
        ),
      );
    }

    // Kein Bild ausgewählt - Platzhalter
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_search_rounded,
              size: isSmallScreen ? 60 : 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Kein Bild ausgewählt',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bitte wähle ein Bild aus oder nimm ein Foto auf',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Function() onTap,
    bool isLoading = false,
    required bool isSmallScreen,
  }) {
    return BounceButton(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: isSmallScreen ? 140 : 160,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withGreen(180),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
