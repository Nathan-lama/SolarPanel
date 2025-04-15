import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/roof_pan.dart';
import '../../services/pvgis_service.dart';
import '../painters/sun_path_painter.dart';

class HorizonChartWidget extends StatelessWidget {
  final RoofPan roofPan;
  final double latitude;

  const HorizonChartWidget({
    super.key,
    required this.roofPan,
    required this.latitude,
  });

  @override
  Widget build(BuildContext context) {
    final List<double>? horizonValues = PVGISService.convertShadowMeasuresToHorizon(
      roofPan.shadowMeasurements
    );
    
    if (horizonValues == null || horizonValues.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masque d\'horizon et trajectoires solaires',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Diagramme polaire
            SizedBox(
              height: 350,
              child: _buildSunPathChart(horizonValues),
            ),
            
            const SizedBox(height: 16),
            
            // Légende du graphique
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Masque d\'horizon', Colors.red),
                const SizedBox(width: 16),
                _buildLegendItem('Soleil en juin', Colors.orange),
                const SizedBox(width: 16),
                _buildLegendItem('Soleil en décembre', Colors.blue),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Garder le tableau de valeurs d'horizon mais en le rendant pliable
            ExpansionTile(
              title: const Text('Valeurs détaillées du masque d\'horizon'),
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: horizonValues.length,
                  itemBuilder: (context, index) {
                    final azimuth = index * 10;
                    final String cardinalPoint = _getCardinalPointForAzimuth(azimuth);
                    
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$azimuth° ${cardinalPoint.isNotEmpty ? "($cardinalPoint)" : ""}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${horizonValues[index].toStringAsFixed(1)}°',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget pour un élément de légende
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
  
  // Widget pour créer le diagramme polaire des trajectoires solaires
  Widget _buildSunPathChart(List<double> horizonValues) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = min(constraints.maxWidth, constraints.maxHeight);
        final double centerX = size / 2;
        final double centerY = size / 2;
        final double radius = size / 2 - 30;
        
        // Obtenir les données pour les trajectoires solaires
        final List<Map<String, double>> summerSunPath = _calculateSunPath(true, latitude);
        final List<Map<String, double>> winterSunPath = _calculateSunPath(false, latitude);
        
        return CustomPaint(
          size: Size(size, size),
          painter: SunPathPainter(
            horizonValues: horizonValues,
            summerSunPath: summerSunPath,
            winterSunPath: winterSunPath,
            centerX: centerX,
            centerY: centerY,
            radius: radius,
          ),
        );
      }
    );
  }
  
  // Calcule la trajectoire du soleil pour un jour donné
  List<Map<String, double>> _calculateSunPath(bool isSummer, double latitude) {
    List<Map<String, double>> sunPath = [];
    
    // Déclinaison solaire - approximation
    // 23.45 degrés pour le solstice d'été, -23.45 pour le solstice d'hiver
    final double declination = isSummer ? 23.45 : -23.45;
    
    // Pour chaque heure de la journée (pas de 5 degrés d'angle horaire)
    for (int hourAngle = -180; hourAngle <= 180; hourAngle += 5) {
      // Calcul basé sur les formules de position solaire
      double hourAngleRad = hourAngle * pi / 180;
      double latitudeRad = latitude * pi / 180;
      double declinationRad = declination * pi / 180;
      
      // Altitude solaire (élévation)
      double sinAltitude = sin(declinationRad) * sin(latitudeRad) + 
                         cos(declinationRad) * cos(latitudeRad) * cos(hourAngleRad);
      double altitude = asin(sinAltitude) * 180 / pi;
      
      // Azimut solaire (0 = Sud, positif vers l'Ouest)
      double cosAzimuth = (sin(declinationRad) - sin(latitudeRad) * sinAltitude) / 
                          (cos(latitudeRad) * cos(asin(sinAltitude)));
      cosAzimuth = cosAzimuth.clamp(-1.0, 1.0); // Éviter les erreurs d'approximation
      double azimuth = acos(cosAzimuth) * 180 / pi;
      
      // Correction du signe de l'azimut
      if (hourAngle > 0) {
        azimuth = 360 - azimuth;
      }
      
      // Convertir l'azimut vers notre convention (0 = Nord, 90 = Est)
      azimuth = (azimuth + 180) % 360;
      
      // N'ajouter que les points où le soleil est au-dessus de l'horizon
      if (altitude > 0) {
        sunPath.add({
          'azimuth': azimuth,
          'altitude': altitude,
        });
      }
    }
    
    return sunPath;
  }
  
  String _getCardinalPointForAzimuth(int azimuth) {
    switch (azimuth) {
      case 0: return 'N';
      case 90: return 'E';
      case 180: return 'S';
      case 270: return 'O';
      case 45: return 'NE';
      case 135: return 'SE';
      case 225: return 'SO';
      case 315: return 'NO';
      default: return '';
    }
  }
}
