import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/diagnostic_result.dart';
import '../models/custom_image_content_item.dart';

// the main scanner screen — lets users take a photo or pick from gallery and get an AI diagnosis
class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
  CameraController? _cameraController;
  final ImagePicker _picker = ImagePicker();
  bool _isInitializing = true;
  bool _isScanning = false;
  bool _cameraPermissionDenied = false;
  AppState? _appState;

  // skipping hardware setup entirely on web/desktop since camera isn't available there
  static final bool _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // returns true when the camera has actually finished initializing and is ready to use
  bool get _cameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    _initializeGroq();
    if (!_isMobile) {
      _isInitializing = false;
    } else {
      _isInitializing = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newAppState = Provider.of<AppState>(context);
    if (_appState != newAppState) {
      _appState?.removeListener(_onTabChanged);
      _appState = newAppState;
      _appState?.addListener(_onTabChanged);
    }
    _onTabChanged();
  }

  void _onTabChanged() {
    if (_appState == null || !_isMobile) return;
    final isVisible = _appState!.currentIndex == 1; // Scan tab index
    if (isVisible) {
      if (_cameraController == null && !_isInitializing && !_cameraPermissionDenied) {
        _initializeCamera();
      }
    } else {
      if (_cameraController != null) {
        _disposeCamera();
      }
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      final controller = _cameraController;
      _cameraController = null;
      if (mounted) setState(() {});
      await controller?.dispose();
    }
  }

  void _initializeGroq() {
    // ⚠️ ADD YOUR OWN GROQ API CREDENTIALS BELOW
    // Get your API key from: https://console.groq.com/keys
    OpenAI.baseUrl = 'YOUR_GROQ_BASE_URL';  // e.g. 'https://api.groq.com/openai'
    OpenAI.apiKey = 'YOUR_GROQ_API_KEY';     // e.g. 'gsk_...'
  }

  Future<void> _initializeCamera() async {
    if (mounted) setState(() { _isInitializing = true; _cameraPermissionDenied = false; });

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) setState(() => _isInitializing = false);
      return;
    }

    // clean up the old controller before spinning up a new one — prevents a resource leak
    await _cameraController?.dispose();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
    } catch (e) {
      debugPrint('Camera initialisation error: $e');
      // if permission was denied show a message and let them retry instead of crashing
      if (mounted) setState(() => _cameraPermissionDenied = true);
      await _cameraController?.dispose();
      _cameraController = null;
    }
    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _processImage(XFile imageFile) async {
    setState(() => _isScanning = true);

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      const promptText = '''
Analyze this plant image. You must strictly respond with a single, raw JSON object matching this schema exactly:
{
  "plant_name": "Common name of the plant",
  "scientific_name": "Scientific botanical name",
  "health_status": "Healthy" or "Diseased",
  "disease_name": "Name of disease if diseased, otherwise null",
  "cure_instructions": "Step-by-step advice on how to cure or maintain this plant based on the image status",
  "toxicity_human": "Safe" or "Toxic if ingested",
  "toxicity_pets": "Safe" or "Toxic to dogs/cats"
}
''';

      final chatCompletion = await OpenAI.instance.chat.create(
        model: 'llama-3.2-90b-vision-preview',
        responseFormat: {'type': 'json_object'},
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  promptText),
              CustomImageContentItem(
                  'data:image/jpeg;base64,$base64Image'),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      final responseText =
          chatCompletion.choices.first.message.content?.first.text;
      if (responseText != null && mounted) {
        final decodedJson = jsonDecode(responseText) as Map<String, dynamic>;
        _showResultModal(DiagnosticResult.fromJson(decodedJson));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vision analysis error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showResultModal(DiagnosticResult result) {
    final bool isHealthy = result.healthStatus == 'Healthy';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // small drag handle at the top of the modal sheet
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(result.plantName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text(result.scientificName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey)),
              const SizedBox(height: 16),
              // chip showing if the plant is healthy or has a disease
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isHealthy
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHealthy
                          ? Icons.check_circle_rounded
                          : Icons.warning_rounded,
                      color: isHealthy
                          ? const Color(0xFF2E7D32)
                          : Colors.orange[800],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.diseaseName ?? result.healthStatus,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isHealthy
                            ? const Color(0xFF2E7D32)
                            : Colors.orange[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(result.cureInstructions,
                  style: const TextStyle(fontSize: 14, height: 1.55)),
              const SizedBox(height: 20),
              // shows toxicity for humans and pets side by side
              Row(
                children: [
                  _ToxicityChip(
                      label: '👤 Human: ${result.toxicityHuman}',
                      safe: result.toxicityHuman == 'Safe'),
                  const SizedBox(width: 10),
                  _ToxicityChip(
                      label: '🐾 Pets: ${result.toxicityPets}',
                      safe: result.toxicityPets == 'Safe'),
                ],
              ),
                  const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _appState?.removeListener(_onTabChanged);
    _cameraController?.dispose();
    super.dispose();
  }

  // this is shown on web/desktop where the camera isn't available — lets them pick from gallery instead
  Widget _buildSimulationUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.document_scanner_rounded,
                    size: 64, color: Colors.greenAccent),
              ),
              const SizedBox(height: 28),
              const Text(
                'Simulation Mode',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'The live camera requires an Android or iOS device.\n'
                'Use the Gallery button to analyse a saved plant photo.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null && mounted) {
                    setState(() => _isScanning = true);
                    await _processImage(image);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.photo_library_rounded),
                label: Text(_isScanning ? 'Analysing…' : 'Pick from Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // if we're not on mobile, show the simpler gallery-only screen
    if (!_isMobile) return _buildSimulationUI();

    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // show the camera feed behind everything else
          if (_cameraReady)
            Positioned.fill(child: CameraPreview(_cameraController!)),

          // if permission was denied show this overlay explaining what to do
          if (_cameraPermissionDenied)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_photography_rounded,
                            color: Colors.white54, size: 64),
                        const SizedBox(height: 20),
                        const Text(
                          'Camera Permission Required',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Please allow camera access in your device Settings, then tap Retry.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              height: 1.5),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: _initializeCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 14),
            // even when camera is blocked I still let them pick from gallery
                        TextButton.icon(
                          onPressed: () async {
                            final image = await _picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) _processImage(image);
                          },
                          icon: const Icon(Icons.photo_library_rounded,
                              color: Colors.white54),
                          label: const Text('Or pick from Gallery',
                              style: TextStyle(color: Colors.white54)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // the green rectangle that shows the user where to point the camera
          if (!_cameraPermissionDenied)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.width * 0.75,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 2.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isScanning
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Colors.greenAccent))
                    : const SizedBox.shrink(),
              ),
            ),

          // bottom buttons for gallery and capture — hidden if permission overlay is showing
          if (!_cameraPermissionDenied)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'gallery_btn',
                    onPressed: _isScanning
                        ? null
                        : () async {
                            final image = await _picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) _processImage(image);
                          },
                    backgroundColor: Colors.white,
                    icon: const Icon(Icons.photo_library, color: Colors.green),
                    label: const Text('Gallery',
                        style: TextStyle(color: Colors.green)),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.extended(
                    heroTag: 'camera_btn',
                    // guard check so we don't crash if camera isn't ready yet
                    onPressed: _isScanning || !_cameraReady
                        ? null
                        : () async {
                            final image =
                                await _cameraController!.takePicture();
                            _processImage(image);
                          },
                    backgroundColor:
                        _cameraReady ? Colors.green : Colors.grey,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Capture',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// small color-coded chip that shows if something is safe or toxic
class _ToxicityChip extends StatelessWidget {
  final String label;
  final bool safe;
  const _ToxicityChip({required this.label, required this.safe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: safe
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: safe ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        ),
      ),
    );
  }
}
