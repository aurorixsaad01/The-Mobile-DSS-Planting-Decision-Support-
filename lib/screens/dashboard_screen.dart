import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/plant_model.dart';
import '../services/weather_service.dart';
import 'plant_onboarding.dart';

// the main screen users land on — shows weather, plant tools, and the garden list
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WeatherService _weatherService = WeatherService();

  String _tempDisplay = '--°C';
  String _weatherRecommendation = 'Fetching local conditions…';
  bool _isSimulated = false;
  bool _weatherLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final data = await _weatherService.fetchWeather();

    if (!mounted) return;

    final temp = data['temperature_2m'] as double?;
    final rain = data['precipitation'] as double? ?? 0.0;
    final simulated = data['simulated'] == true;

    setState(() {
      _tempDisplay = temp != null ? '${temp.toStringAsFixed(1)}°C' : '--°C';
      _weatherRecommendation = temp != null
          ? _weatherService.getWeatherRecommendation(temp, rain)
          : 'Unable to fetch local weather.';
      _isSimulated = simulated;
      _weatherLoaded = true;
    });
  }

  void _openPlantOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantOnboardingScreen(
          weatherContext: _weatherRecommendation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plants = context.watch<AppState>().myPlants;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: CustomScrollView(
            slivers: [
          // sticky top bar that stays pinned while scrolling
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 2,
            title: const Text(
              'My Garden',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh weather',
                onPressed: _loadWeather,
              ),
            ],
          ),

          // weather card just below the app bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _WeatherRecommendationCard(
                tempDisplay: _tempDisplay,
                recommendation: _weatherRecommendation,
                isSimulated: _isSimulated,
                isLoaded: _weatherLoaded,
                plantCount: plants.length,
              ),
            ),
          ),

          // the 4 tool shortcuts in a grid layout
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Plant Tools'),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // wider screens get 4 columns, phones get 2
                      final crossAxisCount =
                          constraints.maxWidth > 480 ? 4 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio:
                            crossAxisCount == 4 ? 1.1 : 1.55,
                        children: [
                          _ToolCard(
                            title: 'Plant Identifier',
                            subtitle: 'Diagnose diseases',
                            icon: Icons.document_scanner_rounded,
                            gradientColors: const [
                              Color(0xFF43A047),
                              Color(0xFF1B5E20),
                            ],
                            onTap: () =>
                                context.read<AppState>().setTab(1),
                          ),
                          _ToolCard(
                            title: 'Light Meter',
                            subtitle: 'Measure lux levels',
                            icon: Icons.wb_sunny_rounded,
                            gradientColors: const [
                              Color(0xFFFFA726),
                              Color(0xFFE65100),
                            ],
                            onTap: () =>
                                context.read<AppState>().setTab(2),
                          ),
                          _ToolCard(
                            title: 'Ask Botanist',
                            subtitle: 'Chat with Alifs',
                            icon: Icons.psychology_rounded,
                            gradientColors: const [
                              Color(0xFF26C6DA),
                              Color(0xFF006064),
                            ],
                            onTap: () =>
                                context.read<AppState>().setTab(3),
                          ),
                          _ToolCard(
                            title: 'Add Plant',
                            subtitle: 'Grow your garden',
                            icon: Icons.add_circle_rounded,
                            gradientColors: const [
                              Color(0xFFAB47BC),
                              Color(0xFF4A148C),
                            ],
                            onTap: _openPlantOnboarding,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // the user's saved plants section below the tool grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel(label: 'My Garden'),
                  if (plants.isNotEmpty)
                    TextButton.icon(
                      onPressed: _openPlantOnboarding,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Plant'),
                    ),
                ],
              ),
            ),
          ),

          // show empty state when no plants, or scroll through cards if there are some
          if (plants.isEmpty)
            const SliverToBoxAdapter(child: _EmptyGardenState())
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 195,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: plants.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return _PlantCard(plant: plants[index]);
                  },
                ),
              ),
            ),

          // just some breathing room at the bottom so the FAB doesn't overlap anything
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPlantOnboarding,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Plant',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// the green banner card at the top showing temp and what to plant today
class _WeatherRecommendationCard extends StatelessWidget {
  final String tempDisplay;
  final String recommendation;
  final bool isSimulated;
  final bool isLoaded;
  final int plantCount;

  const _WeatherRecommendationCard({
    required this.tempDisplay,
    required this.recommendation,
    required this.isSimulated,
    required this.isLoaded,
    required this.plantCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF388E3C), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // shows the temperature with a SIM badge when we're using fake data
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.thermostat_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      tempDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isSimulated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('SIM',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // shows how many plants are in their garden
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grass, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$plantCount plant${plantCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoaded)
            Text(
              recommendation,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

// each tool on the dashboard — tapping one navigates to that feature
class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// individual plant card that scrolls horizontally in the garden section
class _PlantCard extends StatelessWidget {
  final PlantModel plant;
  const _PlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final bool overdue = plant.needsWater;
    final Color statusColor = overdue ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final Color statusBg = overdue
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFE8F5E9);

    return Container(
      width: 165,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // plant icon on the left and the quick-water button on the right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 22)),
                  ),
                ),
                // tap the drop icon to log a watering right now
                GestureDetector(
                  onTap: () {
                    context.read<AppState>().waterPlant(plant.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('💧 ${plant.name} watered!'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('💧', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // common name big and bold
            Text(
              plant.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1B2124),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // the latin name in italic below the common name
            Text(
              plant.scientificName,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9E9E9E),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // the little pill showing how many days until watering is due
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    overdue
                        ? Icons.warning_amber_rounded
                        : Icons.water_drop_rounded,
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      plant.wateringLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// the placeholder I show when the user hasn't added any plants yet
class _EmptyGardenState extends StatelessWidget {
  const _EmptyGardenState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🪴', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your garden is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2124),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Plant" to create your first care profile and get a personalised AI plan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// bold section heading I reuse in a few places on the dashboard
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1B2124),
        letterSpacing: -0.3,
      ),
    );
  }
}
