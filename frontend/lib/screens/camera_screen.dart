import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'dart:html' as html;
import 'dart:ui' as ui;

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  XFile? _image;
  bool _isLoading = false;
  String _error = '';

  html.VideoElement? _webcamVideo;
  html.CanvasElement? _canvas;
  html.CanvasRenderingContext2D? _canvasContext;
  Uint8List? _capturedWebImage;

  bool _showWebcam = false;
  bool _showConfirmButton = false;

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
    });
    _initializeWebCamera();
  }

  void _captureWebcamImage() {
    _canvas = html.CanvasElement(
        width: _webcamVideo!.videoWidth, height: _webcamVideo!.videoHeight);
    _canvasContext = _canvas!.getContext('2d') as html.CanvasRenderingContext2D;
    _canvasContext!.drawImage(_webcamVideo!, 0, 0);

    _canvas!.toBlob().then((blob) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      reader.onLoadEnd.listen((event) {
        setState(() {
          _capturedWebImage = reader.result as Uint8List;
          _showConfirmButton = true;
        });
      });
    });
  }

  void _confirmCapturedImage() {
    setState(() {
      _showWebcam = false;
      _showConfirmButton = false;
      _webcamVideo?.srcObject = null;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Snap / Select')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bananas.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (kIsWeb && _showWebcam)
                  Column(
                    children: [
                      const Text('Live Webcam'),
                      SizedBox(
                        height: 250,
                        child: HtmlElementView(viewType: 'webcamElement'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _captureWebcamImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Foto aufnehmen'),
                      ),
                    ],
                  ),
                if (kIsWeb && _capturedWebImage != null)
                  Column(
                    children: [
                      Image.memory(_capturedWebImage!, height: 200),
                      const SizedBox(height: 10),
                      if (_showConfirmButton)
                        ElevatedButton.icon(
                          onPressed: _confirmCapturedImage,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Bild übernehmen'),
                        ),
                    ],
                  ),
                if (kIsWeb && _image != null && _capturedWebImage == null)
                  FutureBuilder<Uint8List>(
                    future: _image!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return Image.memory(snapshot.data!, height: 200);
                      } else if (snapshot.hasError) {
                        return const Text("Fehler beim Laden des Bildes");
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                if (!kIsWeb && _image != null)
                  Image.file(
                    File(_image!.path),
                    height: 200,
                  ),
                const SizedBox(height: 20),
                if (_error.isNotEmpty)
                  Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    if (kIsWeb)
                      ElevatedButton.icon(
                        onPressed: _startWebcam,
                        icon: const Icon(Icons.videocam),
                        label: const Text("Webcam öffnen"),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _getImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera öffnen'),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _getImage(ImageSource.gallery),
                      icon: const Icon(Icons.image),
                      label: const Text('Bild auswählen'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _uploadImage,
                      icon: const Icon(Icons.send),
                      label: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Bild hochladen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
