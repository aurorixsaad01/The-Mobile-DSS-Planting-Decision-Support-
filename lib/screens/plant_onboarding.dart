import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/plant_model.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';

// the form the user fills out when adding a new plant — name, location, optional photo
class PlantOnboardingScreen extends StatefulWidget {
  final String weatherContext;

  const PlantOnboardingScreen({
    super.key,
    required this.weatherContext,
  });

  @override
  State<PlantOnboardingScreen> createState() => _PlantOnboardingScreenState();
}

class _PlantOnboardingScreenState extends State<PlantOnboardingScreen> {
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();

  String _selectedLocation = 'Balcony / Window';
  XFile? _soilImage;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _snapSoilPhoto() async {
    // camera doesn't work in browser so on web I fall back to the file picker
    final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null && mounted) {
      setState(() => _soilImage = image);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null && mounted) {
      setState(() => _soilImage = image);
    }
  }

  int _parseWateringInterval(String aiInstructions) {
    final text = aiInstructions.toLowerCase();
    if (text.contains('every day') || text.contains('daily')) return 1;
    if (text.contains('every 2 days') || text.contains('2 days')) return 2;
    if (text.contains('every 3 days') || text.contains('3 days')) return 3;
    if (text.contains('every 4 days') || text.contains('4 days')) return 4;
    if (text.contains('every 5 days') || text.contains('5 days')) return 5;
    if (text.contains('week') || text.contains('7 days')) return 7;
    return 3; // most houseplants are fine on a 3 day schedule if I can't figure it out
  }

  Future<void> _generatePlanAndSave() async {
    final plantName = _nameController.text.trim();
    if (plantName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plant name first.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    // I read the image bytes here before any await so the context doesn't go stale
    List<int>? bytes;
    if (_soilImage != null) {
      bytes = await _soilImage!.readAsBytes();
    }

    final diagnosis = await _geminiService.generateCarePlan(
      plantName: plantName,
      location: _selectedLocation,
      weatherContext: widget.weatherContext,
      imageBytes: bytes,
    );

    // grab everything I need from context right now before the next await happens
    if (!mounted) return;

    final appState = context.read<AppState>();
    final notificationService = context.read<NotificationService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final int intervalDays = _parseWateringInterval(diagnosis);
    final int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final newPlant = PlantModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: plantName,
      scientificName: 'Custom Setup',
      temperatureRange: 'Adaptive to local weather',
      sunlightRequirement: _selectedLocation,
      soilType: 'Standard mix',
      waterIntervalDays: intervalDays,
      lastWatered: DateTime.now(),
      careInstructions: diagnosis,
      hardinessZone: '9 to 12',
    );

    // add the plant to state first so the dashboard refreshes right away
    appState.addPlant(newPlant);

    // fire off the notifications after — safe to await because I already grabbed context above
    await notificationService.showInstantNotification(
      title: '🌱 $plantName Added!',
      body:
          'Smart scheduling analysed your local parameters. Reminder set for every $intervalDays days.',
    );

    await notificationService.scheduleRecurringNotification(
      id: notificationId,
      title: '💧 Time to check your $plantName!',
      body:
          'Based on your setup and local weather, it\'s time to water and check soil moisture.',
      daysInterval: intervalDays,
    );

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
            '✨ $plantName registered! Reminder set for every $intervalDays days.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2E7D32)),
              const SizedBox(height: 28),
              const Text(
                'Generating your personalised care plan…',
                style: TextStyle(
                    fontSize: 15, color: Color(0xFF546E7A)),
              ),
              const SizedBox(height: 8),
              Text(
                'Analysing weather and soil conditions',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Plant',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // section for the plant name input
            const Text('What plant are you adding?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Monstera, Basil, Rose…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.grass),
              ),
            ),
            const SizedBox(height: 28),

            // section where the user picks indoors/balcony/garden etc.
            const Text('Where will this plant live?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                'Indoor (Low Light)',
                'Balcony / Window',
                'Outdoor Garden',
                'Terrace / Roof',
              ]
                  .map((loc) =>
                      DropdownMenuItem(value: loc, child: Text(loc)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLocation = val);
                }
              },
            ),
            const SizedBox(height: 28),

            // optional soil photo — helps the AI give better watering advice
            const Text('Soil or seed photo (optional)',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const Text(
              'AI can adjust watering needs based on your soil image.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PhotoButton(
                    icon: kIsWeb
                        ? Icons.photo_library_rounded
                        : Icons.camera_alt_rounded,
                    label: kIsWeb ? 'Upload Photo' : 'Take Photo',
                    onTap: _snapSoilPhoto,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: _pickFromGallery,
                  ),
                ),
              ],
            ),
            if (_soilImage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 8),
                    Text('Photo selected — AI will use it for analysis',
                        style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),

            // the big generate button at the bottom
            ElevatedButton(
              onPressed: _generatePlanAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor:
                    const Color(0xFF2E7D32).withValues(alpha: 0.4),
              ),
              child: const Text(
                'Generate Care Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// the camera/gallery button used in the soil photo section
class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}
