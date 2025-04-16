import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SunPathPainter extends CustomPainter {
  final List<double> horizonValues;
  final List<Map<String, double>> summerSunPath;
  final List<Map<String, double>> winterSunPath;
  final double centerX;
  final double centerY;
  final double radius;
  
  SunPathPainter({
    required this.horizonValues,
    required this.summerSunPath,
    required this.winterSunPath,
    required this.centerX,
    required this.centerY,
    required this.radius,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner une sphère complète comme fond du graphique
    _drawSphere(canvas);
    
    // Dessiner les cercles de référence et les lignes de grille
    _drawGrid(canvas);
    
    // Dessiner les trajectoires du soleil
    _drawSunPath(canvas, winterSunPath, Colors.blue);  // En hiver, trajet plus bas
    _drawSunPath(canvas, summerSunPath, Colors.orange); // En été, trajet plus haut
    
    // Dessiner les masques d'horizon
    _drawHorizon(canvas);
    
    // Dessiner les points cardinaux
    _drawCardinalPoints(canvas);
  }
  
  // Nouvelle méthode pour dessiner une sphère
  void _drawSphere(Canvas canvas) {
    // Get the base color
    final Color baseColor = Colors.blue.shade100;
    
    // Create a new color with the desired opacity using withAlpha
    final Paint spherePaint = Paint()
      ..color = baseColor.withAlpha(51)  // 0.2 * 255 = ~51
      ..style = PaintingStyle.fill;
      
    // Cercle extérieur représentant la sphère céleste
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      spherePaint,
    );
    
    // Bordure de la sphère
    final Paint borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      borderPaint,
    );
  }
  
  void _drawGrid(Canvas canvas) {
    // Style pour les cercles concentriques
    final Paint circlePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Cercles d'altitude (de 0° à 90° par pas de 15°)
    for (int altitude = 15; altitude <= 90; altitude += 15) {
      double circleRadius = radius * (90 - altitude) / 90;
      canvas.drawCircle(
        Offset(centerX, centerY),
        circleRadius,
        circlePaint,
      );
      
      // Ajouter le texte d'altitude avec la bonne référence à TextDirection
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '$altitude°',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX + 2, centerY - circleRadius - textPainter.height),
      );
    }
    
    // Lignes d'azimut (de 0° à 330° par pas de 30°)
    for (int azimuth = 0; azimuth < 360; azimuth += 30) {
      final double startX = centerX;
      final double startY = centerY;
      final double endX = centerX + radius * sin(azimuth * pi / 180);
      final double endY = centerY - radius * cos(azimuth * pi / 180);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        circlePaint,
      );
    }
  }
  
  // Correction de la méthode pour dessiner l'horizon
  void _drawHorizon(Canvas canvas) {
    final Paint horizonPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final Path horizonPath = Path();
    bool started = false;
    
    // Tracer le masque d'horizon
    for (int i = 0; i < horizonValues.length; i++) {
      final double azimuth = i * 10.0;
      final double elevation = horizonValues[i];
      
      // Convertir en coordonnées cartésiennes
      final double distance = radius * (90 - elevation) / 90;
      final double x = centerX + distance * sin(azimuth * pi / 180);
      final double y = centerY - distance * cos(azimuth * pi / 180);
      
      if (!started) {
        horizonPath.moveTo(x, y);
        started = true;
      } else {
        horizonPath.lineTo(x, y);
      }
    }
    
    // Fermer le chemin en reliant au premier point
    if (started && horizonValues.isNotEmpty) {
      final double firstAzimuth = 0.0;
      final double firstElevation = horizonValues[0];
      final double distance = radius * (90 - firstElevation) / 90;
      final double x = centerX + distance * sin(firstAzimuth * pi / 180);
      final double y = centerY - distance * cos(firstAzimuth * pi / 180);
      horizonPath.lineTo(x, y);
      
      // Dessiner le chemin sans le fermer
      canvas.drawPath(horizonPath, horizonPaint);
      
      // Zone d'ombre pour les obstacles
      final Paint shadowPaint = Paint()
        ..color = Colors.red.withAlpha(26)  // 0.1 * 255 = ~26
        ..style = PaintingStyle.fill;
      
      // Créer un chemin fermé pour la zone d'ombre
      final Path shadowPath = Path.from(horizonPath);
      shadowPath.lineTo(centerX + radius, centerY); // Bord droit
      shadowPath.arcTo(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        0, 
        2 * pi, 
        false
      );
      shadowPath.close();
      
      canvas.drawPath(shadowPath, shadowPaint);
    }
  }
  
  void _drawSunPath(Canvas canvas, List<Map<String, double>> sunPath, Color color) {
    final Paint sunPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final Path path = Path();
    bool started = false;
    
    for (var point in sunPath) {
      final double azimuth = point['azimuth']!;
      final double altitude = point['altitude']!;
      
      // Convertir en coordonnées cartésiennes
      final double distance = radius * (90 - altitude) / 90;
      final double x = centerX + distance * sin(azimuth * pi / 180);
      final double y = centerY - distance * cos(azimuth * pi / 180);
      
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, sunPaint);
  }
  
  void _drawCardinalPoints(Canvas canvas) {
    final Map<int, String> cardinalPoints = {
      0: 'N',
      90: 'E',
      180: 'S',
      270: 'O',
      45: 'NE',
      135: 'SE',
      225: 'SO',
      315: 'NO',
    };
    
    for (var entry in cardinalPoints.entries) {
      final int azimuth = entry.key;
      final String label = entry.value;
      
      final double x = centerX + (radius + 15) * sin(azimuth * pi / 180);
      final double y = centerY - (radius + 15) * cos(azimuth * pi / 180);
      
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(minWidth: 20);
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }
  
  @override
  bool shouldRepaint(SunPathPainter oldDelegate) {
    return horizonValues != oldDelegate.horizonValues ||
           summerSunPath != oldDelegate.summerSunPath ||
           winterSunPath != oldDelegate.winterSunPath;
  }
}
