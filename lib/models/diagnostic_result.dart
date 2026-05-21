class DiagnosticResult {
  final String plantName;
  final String scientificName;
  final String healthStatus;
  final String? diseaseName;
  final String cureInstructions;
  final String toxicityHuman;
  final String toxicityPets;

  DiagnosticResult({
    required this.plantName,
    required this.scientificName,
    required this.healthStatus,
    this.diseaseName,
    required this.cureInstructions,
    required this.toxicityHuman,
    required this.toxicityPets,
  });

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticResult(
      plantName: json['plant_name'] ?? 'Unknown Plant',
      scientificName: json['scientific_name'] ?? 'Unknown Species',
      healthStatus: json['health_status'] ?? 'Healthy',
      diseaseName: json['disease_name'],
      cureInstructions: json['cure_instructions'] ?? 'No special care needed.',
      toxicityHuman: json['toxicity_human'] ?? 'Safe',
      toxicityPets: json['toxicity_pets'] ?? 'Safe',
    );
  }
}
