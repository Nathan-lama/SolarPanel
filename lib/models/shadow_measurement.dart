class ShadowMeasurement {
  final double azimuth; // Angle par rapport au nord (0-360°)
  final double elevation; // Angle vers le haut (0-90°)
  final DateTime timestamp;

  ShadowMeasurement({
    required this.azimuth,
    required this.elevation,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'azimuth': azimuth,
      'elevation': elevation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Pour convertir en ligne CSV
  List<dynamic> toCsvRow() {
    return [
      azimuth.toStringAsFixed(2),
      elevation.toStringAsFixed(2),
      timestamp.toIso8601String(),
    ];
  }

  static List<String> csvHeaders() {
    return ['Azimuth (°)', 'Elevation (°)', 'Timestamp'];
  }
}
