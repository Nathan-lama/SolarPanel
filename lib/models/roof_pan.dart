import 'dart:math';

class RoofPan {
  final String id;
  final double orientation;
  final double inclination;
  final bool hasObstacles;
  final String? obstaclesVideoPath;

  RoofPan({
    required this.orientation,
    required this.inclination,
    this.hasObstacles = false,
    this.obstaclesVideoPath,
  }) : id = Random().nextDouble().toString();

  @override
  String toString() {
    return 'Orientation: ${orientation.round()}°, Inclinaison: ${inclination.round()}°${hasObstacles ? " (Obstacles)" : ""}';
  }
}
