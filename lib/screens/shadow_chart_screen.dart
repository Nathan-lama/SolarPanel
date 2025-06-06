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
        title: const Text('Masques d\'ombre'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Diagramme prenant tout l'espace
          Positioned.fill(
            child: CustomPaint(
              painter: PolarChartPainter(measurements),
              size: Size.infinite,
            ),
          ),
          
          // Compteur de mesures en haut
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153), // Remplacé withOpacity(0.6) par withAlpha(153)
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${measurements.length} mesures',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Légende minimaliste au bas de l'écran
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153), // Remplacé withOpacity(0.6) par withAlpha(153)
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'N = 0° | E = 90° | S = 180° | O = 270°',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Centre = 90° élévation | Bord = 0° élévation',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
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
