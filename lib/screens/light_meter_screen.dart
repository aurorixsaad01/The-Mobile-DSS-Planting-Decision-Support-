import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:light/light.dart';

// reads the ambient light sensor and tells the user what plants suit their spot
class LightMeterScreen extends StatefulWidget {
  const LightMeterScreen({super.key});

  @override
  State<LightMeterScreen> createState() => _LightMeterScreenState();
}

class _LightMeterScreenState extends State<LightMeterScreen>
    with SingleTickerProviderStateMixin {
  Light? _light;
  StreamSubscription<int>? _subscription;

  int _currentLux = 0;
  String _lightCategory = 'Measuring…';
  Color _themeColor = const Color(0xFF43A047);
  String _plantMatch = '';

  // Non-mobile simulation state
  static final bool _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  late final AnimationController _simAnimController;
  late final Animation<double> _simAnimation;

  @override
  void initState() {
    super.initState();

    if (_isMobile) {
      _startListeningToLight();
    } else {
      // on web/desktop I animate a fake lux value so the UI still looks alive
      _simAnimController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat(reverse: true);

      _simAnimation = Tween<double>(begin: 300, end: 2800).animate(
        CurvedAnimation(parent: _simAnimController, curve: Curves.easeInOut),
      )..addListener(() {
          final simulatedLux = _simAnimation.value.toInt();
          if (mounted) {
            setState(() {
              _currentLux = simulatedLux;
              _interpretLuxValues(simulatedLux);
            });
          }
        });
    }
  }

  void _startListeningToLight() {
    _light = Light();
    try {
      _subscription = _light?.lightSensorStream.listen((int luxValue) {
        if (mounted) {
          setState(() {
            _currentLux = luxValue;
            _interpretLuxValues(luxValue);
          });
        }
      });
    } catch (e) {
      debugPrint('Light sensor not available: $e');
      setState(() => _lightCategory = 'Sensor not detected');
    }
  }

  void _interpretLuxValues(int lux) {
    if (lux < 500) {
      _lightCategory = 'Low Light';
      _plantMatch = 'Ferns, Calatheas, Peace Lily';
      _themeColor = const Color(0xFF546E7A);
    } else if (lux < 2500) {
      _lightCategory = 'Bright Indirect Light';
      _plantMatch = 'Monstera, Pothos, Philodendron';
      _themeColor = const Color(0xFF43A047);
    } else {
      _lightCategory = 'Direct Sunlight';
      _plantMatch = 'Succulents, Cacti, Lavender';
      _themeColor = const Color(0xFFFFA726);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    if (!_isMobile) {
      _simAnimController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progressFraction = (_currentLux / 5000).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Light Meter',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            const SizedBox(height: 16),
            // small badge that tells the user they're seeing simulated data
            if (!_isMobile)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 15, color: Colors.orange),
                    SizedBox(width: 6),
                    Text(
                      'Simulation Mode — Connect a mobile device for live sensor data',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // the big sun icon that changes color based on how bright it is
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _themeColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  key: ValueKey(_themeColor),
                  size: 72,
                  color: _themeColor,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // the big lux number in the center
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '$_currentLux LX',
                key: ValueKey(_currentLux ~/ 100),
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  color: Color(0xFF1B2124),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // text label describing the light level category
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _lightCategory,
                key: ValueKey(_lightCategory),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: _themeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // shows which plants do best in this light level
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _plantMatch.isNotEmpty ? 'Best for: $_plantMatch' : '',
                key: ValueKey(_plantMatch),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // the horizontal bar gauge showing how far along the lux scale we are
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    Text('Ideal',
                        style: TextStyle(
                            color: const Color(0xFF43A047),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    Text('High',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    // the grey track underneath the colored fill
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    // colored fill that grows as lux increases
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 14,
                      width: (MediaQuery.of(context).size.width - 48) *
                          progressFraction,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.greenAccent, _themeColor],
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: _themeColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),

            Text(
              _isMobile
                  ? 'Place your phone next to the plant\'s leaves, facing the '
                    'light source, for an accurate reading.'
                  : 'Light readings are simulated. Use a mobile device for '
                    'live ambient light sensor data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                  height: 1.5),
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }
}
