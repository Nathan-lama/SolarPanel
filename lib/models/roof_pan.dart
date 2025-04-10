import 'dart:math';
import 'shadow_measurement.dart';

class RoofPan {
  final String id;
  final double orientation;
  final double inclination;
  final bool hasObstacles;
  final String? obstaclesVideoPath;
  final List<ShadowMeasurement>? shadowMeasurements;

  RoofPan({
    required this.orientation,
    required this.inclination,
    this.hasObstacles = false,
    this.obstaclesVideoPath,
    this.shadowMeasurements,
  }) : id = Random().nextDouble().toString();

  @override
  String toString() {
    return 'Orientation: ${orientation.round()}°, Inclinaison: ${inclination.round()}°${hasObstacles ? " (Obstacles)" : ""}';
  }
}
