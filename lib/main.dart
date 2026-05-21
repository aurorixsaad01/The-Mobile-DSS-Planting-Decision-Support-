import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/plant_model.dart';
import 'services/notification_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ai_scanner_screen.dart';
import 'screens/light_meter_screen.dart';
import 'screens/botanist_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.initNotification();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const AIGardenerApp(),
    ),
  );
}

// I'm using AppState to hold all the app's data in one place so every screen can access it
class AppState extends ChangeNotifier {
  List<PlantModel> _myPlants = [];
  List<PlantModel> get myPlants => List.unmodifiable(_myPlants);

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  AppState() {
    _loadPlantsFromStorage();
  }

  // this just switches which tab is active at the bottom
  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // used to add a new plant and immediately save it so it persists on restart
  void addPlant(PlantModel newPlant) {
    _myPlants = [..._myPlants, newPlant];
    _savePlantsToStorage();
    notifyListeners(); // tell all screens to rebuild with the new plant
  }

  // I call this when the user taps the water button — resets the countdown for that plant
  void waterPlant(String plantId) {
    _myPlants = _myPlants.map((p) {
      if (p.id == plantId) {
        return p.copyWithWatered();
      }
      return p;
    }).toList();
    _savePlantsToStorage();
    notifyListeners(); // refresh the card so the watering label updates
  }

  void removePlant(String plantId) {
    _myPlants = _myPlants.where((p) => p.id != plantId).toList();
    _savePlantsToStorage();
    notifyListeners();
  }

  // these two functions load and save plants from shared prefs so data survives app restarts
  Future<void> _loadPlantsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? plantsJson = prefs.getString('digital_garden');
    if (plantsJson != null) {
      final List<dynamic> decodedList = json.decode(plantsJson);
      _myPlants = decodedList.map((item) => PlantModel.fromMap(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _savePlantsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData =
        json.encode(_myPlants.map((p) => p.toMap()).toList());
    await prefs.setString('digital_garden', encodedData);
  }
}

// the root widget — sets up the theme and kicks off the app
class AIGardenerApp extends StatelessWidget {
  const AIGardenerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Gardener',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF66BB6A),
          surface: const Color(0xFFF7FAF7),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      home: const MainShell(),
    );
  }
}

// this holds the 4 main screens and switches between them using the bottom nav
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    AiScannerScreen(),
    LightMeterScreen(),
    BotanistChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: IndexedStack(
        index: appState.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.currentIndex,
        onDestinationSelected: context.read<AppState>().setTab,
        backgroundColor: Colors.white,
        indicatorColor:
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.25),
        elevation: 2,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass),
            label: 'Garden',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.light_mode_outlined),
            selectedIcon: Icon(Icons.light_mode),
            label: 'Light Meter',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Botanist',
          ),
        ],
      ),
    );
  }
}
