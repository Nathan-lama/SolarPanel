import 'package:flutter/material.dart';
import 'dart:math';
import '../models/shadow_measurement.dart';

class ShadowChartScreen extends StatelessWidget {
  final List<ShadowMeasurement> measurements;

  const ShadowChartScreen({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualisation des masques d\'ombre'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Diagramme polaire (${measurements.length} mesures)',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomPaint(
                painter: PolarChartPainter(measurements),
                size: Size.infinite,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Comment lire ce graphique :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• L\'angle représente l\'azimut (0° = Nord, 90° = Est, etc.)'),
                    Text('• La distance du centre représente l\'élévation (90° au centre, 0° au bord)'),
                    Text('• Chaque point rouge représente une mesure d\'obstacle'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PolarChartPainter extends CustomPainter {
  final List<ShadowMeasurement> measurements;
  
  PolarChartPainter(this.measurements);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;
    
    // Dessiner les cercles concentriques
    final Paint circlePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 1; i <= 9; i++) {
      canvas.drawCircle(center, radius * i / 9, circlePaint);
    }
    
    // Dessiner les lignes des angles
    final Paint linePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int angle = 0; angle < 360; angle += 30) {
      final double radians = angle * pi / 180;
      final double x = center.dx + cos(radians - pi/2) * radius;
      final double y = center.dy + sin(radians - pi/2) * radius;
      canvas.drawLine(center, Offset(x, y), linePaint);
      
      // Ajouter les labels
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: angle == 0 ? 'N' : angle == 90 ? 'E' : angle == 180 ? 'S' : angle == 270 ? 'O' : '$angle°',
          style: TextStyle(
            color: angle == 0 ? Colors.red : Colors.black,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      final double labelRadius = radius + 10;
      final double labelX = center.dx + cos(radians - pi/2) * labelRadius - textPainter.width / 2;
      final double labelY = center.dy + sin(radians - pi/2) * labelRadius - textPainter.height / 2;
      
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
    
    // Dessiner les points des mesures
    final Paint pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    for (final measurement in measurements) {
      final double azimuth = measurement.azimuth * pi / 180;
      // Conversion de l'élévation: 90° au centre, 0° au bord
      final double elevationRadius = radius * (1 - measurement.elevation / 90);
      
      final double x = center.dx + cos(azimuth - pi/2) * elevationRadius;
      final double y = center.dy + sin(azimuth - pi/2) * elevationRadius;
      
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
