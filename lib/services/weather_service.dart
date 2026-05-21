import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  // takes the raw temp and rain numbers and turns them into a planting suggestion the user can read
  String getWeatherRecommendation(double temp, double rain) {
    if (temp > 32) {
      return '🌞 High Heat Warning: Best time to plant drought-resistant varieties '
          'like Aloe Vera, Succulents, or Jade. Water existing pots early before sunrise.';
    } else if (rain > 5) {
      return '🌧️ Rainy/Monsoon Blend: Ideal atmospheric moisture for propagating '
          'Money Plants, Syngoniums, or Boston Ferns. Ensure soil drainage channels '
          'are completely clear.';
    } else if (temp < 18) {
      return '🍃 Cool Draft Season: Perfect climate metrics for starting microgreens, '
          'Spinach, or Coriander on kitchen windowsills. Shield tropical indoor '
          'varieties from cold drafts.';
    } else {
      return '🌱 Prime Growth Window: Balanced ambient parameters. Highly recommended '
          'to plant Holy Basil (Tulsi), Snake Plants, or Mint today.';
    }
  }

  Future<Map<String, dynamic>> fetchWeather() async {
    // camera and GPS don't work on web/desktop so I just return fake data there
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return _simulatedWeather();
    }

    try {
    // step 1: ask the user for location permission before doing anything else
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      // step 2: grab the device's current GPS coordinates
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('GPS request timed out'),
      );

      // step 3: call Open-Meteo with those coordinates — free weather API, no key needed
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&current=temperature_2m,relative_humidity_2m,precipitation',
      );

      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Weather API request timed out'),
          );

      if (response.statusCode == 200) {
        return json.decode(response.body)['current'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'temperature_2m': null,
        'relative_humidity_2m': null,
        'precipitation': null,
        'error': e.toString(),
      };
    }
  }

  // returns hardcoded weather values when running on web or desktop for testing purposes
  Map<String, dynamic> _simulatedWeather() {
    return {
      'temperature_2m': 26.0,
      'relative_humidity_2m': 65.0,
      'precipitation': 0.0,
      'simulated': true,
    };
  }
}
