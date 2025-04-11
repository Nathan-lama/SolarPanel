import 'shadow_measurement.dart';

class RoofPan {
  final String id;
  final double orientation;
  final double inclination;
  final double peakPower; // Nouvelle propriété pour la puissance crête
  final bool hasObstacles;
  final String? obstaclesVideoPath;
  final List<ShadowMeasurement>? shadowMeasurements;

  RoofPan({
    String? id,
    required this.orientation,
    required this.inclination,
    this.peakPower = 0.0, // Valeur par défaut
    this.hasObstacles = false,
    this.obstaclesVideoPath,
    this.shadowMeasurements,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  @override
  String toString() {
    return 'Orientation: ${orientation.toStringAsFixed(1)}° | '
           'Inclinaison: ${inclination.toStringAsFixed(1)}° | '
           'Puissance: ${peakPower.toStringAsFixed(1)} kWp | '
           'Obstacles: ${hasObstacles ? "Oui" : "Non"}';
  }
}
