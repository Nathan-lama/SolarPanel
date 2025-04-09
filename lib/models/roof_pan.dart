class RoofPan {
  final String id;
  final double orientation; // en degrés
  final double inclination; // en degrés

  RoofPan({
    String? id,
    required this.orientation,
    required this.inclination,
  }) : id = id ?? DateTime.now().toIso8601String();

  @override
  String toString() {
    return 'Orientation: ${orientation.toStringAsFixed(1)}°, Inclinaison: ${inclination.toStringAsFixed(1)}°';
  }
}
