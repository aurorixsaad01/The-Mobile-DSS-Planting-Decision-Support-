class PlantModel {
  final String id;
  final String name;
  final String scientificName;
  final String temperatureRange;
  final String sunlightRequirement;
  final String soilType;
  final int waterIntervalDays;
  final DateTime lastWatered;
  final String careInstructions;
  final String hardinessZone;

  const PlantModel({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.temperatureRange,
    required this.sunlightRequirement,
    required this.soilType,
    required this.waterIntervalDays,
    required this.lastWatered,
    required this.careInstructions,
    required this.hardinessZone,
  });

  // these getters make it easy to check if watering is due without repeating logic everywhere

  // returns true if today is past the next watering date
  bool get needsWater {
    final nextWateringDate = lastWatered.add(Duration(days: waterIntervalDays));
    return DateTime.now().isAfter(nextWateringDate);
  }

  // how many days left until the plant needs water — negative means it's already overdue
  int get daysUntilWater {
    final nextWateringDate = lastWatered.add(Duration(days: waterIntervalDays));
    return nextWateringDate.difference(DateTime.now()).inDays;
  }

  // this gives me a nice readable string I can just drop on the card directly
  String get wateringLabel {
    if (daysUntilWater < 0) return 'Overdue!';
    if (daysUntilWater == 0) return 'Water today';
    return 'Water in ${daysUntilWater}d';
  }

  // I keep the model immutable, so watering creates a fresh copy with the timestamp reset
  PlantModel copyWithWatered() {
    return PlantModel(
      id: id,
      name: name,
      scientificName: scientificName,
      temperatureRange: temperatureRange,
      sunlightRequirement: sunlightRequirement,
      soilType: soilType,
      waterIntervalDays: waterIntervalDays,
      lastWatered: DateTime.now(),
      careInstructions: careInstructions,
      hardinessZone: hardinessZone,
    );
  }

  // used to save/load from SharedPreferences — just turns the model into a map and back

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'temperatureRange': temperatureRange,
      'sunlightRequirement': sunlightRequirement,
      'soilType': soilType,
      'waterIntervalDays': waterIntervalDays,
      'lastWatered': lastWatered.toIso8601String(),
      'careInstructions': careInstructions,
      'hardinessZone': hardinessZone,
    };
  }

  factory PlantModel.fromMap(Map<String, dynamic> map) {
    return PlantModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      scientificName: map['scientificName'] as String? ?? '',
      temperatureRange: map['temperatureRange'] as String? ?? '18–30 °C',
      sunlightRequirement:
          map['sunlightRequirement'] as String? ?? 'Bright indirect light',
      soilType: map['soilType'] as String? ?? 'Well-draining mix',
      waterIntervalDays: map['waterIntervalDays'] as int? ?? 3,
      lastWatered:
          DateTime.tryParse(map['lastWatered'] as String? ?? '') ??
              DateTime.now(),
      careInstructions:
          map['careInstructions'] as String? ?? 'No special instructions.',
      hardinessZone: map['hardinessZone'] as String? ?? '9 to 12',
    );
  }
}
