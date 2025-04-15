import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/roof_pan.dart';
import '../models/shadow_measurement.dart';

class PVGISService {
  // URL for different APIs
  static const String baseUrlPVCalc = "https://re.jrc.ec.europa.eu/api/v5_2/PVcalc";
  static const String baseUrlMRCalc = "https://re.jrc.ec.europa.eu/api/v5_2/MRcalc";
  
  /// Récupère les données de production photovoltaïque depuis l'API PVGIS
  static Future<Map<String, dynamic>> calculateProduction({
    required double latitude,
    required double longitude,
    required RoofPan roofPan,
    required List<double>? horizonValues,
    double systemLoss = 14.0,
  }) async {
    try {
      // Préparation des paramètres pour l'API
      final params = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'outputformat': 'json',
        'peakpower': roofPan.peakPower.toString(),
        'angle': roofPan.inclination.toString(), 
        'aspect': convertAzimuthForAPI(roofPan.orientation).toString(),
        'loss': systemLoss.toString(),
        'mountingplace': 'free', // Installation en plein air
        'pvtechchoice': 'crystSi', // Technologie silicium cristallin
        'raddatabase': 'PVGIS-SARAH2',
        'usehorizon': '1'
      };
      
      // Ajout des données d'horizon si disponibles
      if (horizonValues != null && horizonValues.isNotEmpty) {
        final horizonString = horizonValues.map((v) => v.toString()).join(',');
        params['userhorizon'] = horizonString;
      }
      
      // Construction de l'URL avec paramètres
      final uri = Uri.parse(baseUrlPVCalc).replace(queryParameters: params);
      
      // Envoi de la requête
      final response = await http.get(uri);
      
      // Vérification de la réponse
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la communication avec PVGIS: $e');
    }
  }
  
  /// Récupère les données de radiation mensuelle depuis l'API PVGIS
  static Future<Map<String, dynamic>> getMonthlyRadiation({
    required double latitude,
    required double longitude,
    required double angle,
    required double aspect,
    required List<double>? horizonValues,
    int? year,
  }) async {
    try {
      // Préparation des paramètres pour l'API
      final params = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'outputformat': 'json',
        'angle': angle.toString(),
        'aspect': aspect.toString(),
        'selectrad': '1',  // Plan incliné spécifié
        'horirrad': '1',   // Plan horizontal
        'optrad': '1',     // Plan à angle optimal
        'raddatabase': year != null ? 'PVGIS-ERA5' : 'PVGIS-SARAH2',
        'usehorizon': '1'
      };
      
      // Ajouter l'année spécifique si demandée
      if (year != null) {
        params['startyear'] = year.toString();
        params['endyear'] = year.toString();
      }
      
      // Ajouter l'horizon si disponible
      if (horizonValues != null && horizonValues.isNotEmpty) {
        final horizonString = horizonValues.map((v) => v.toString()).join(',');
        params['userhorizon'] = horizonString;
      }
      
      // Construction de l'URL avec paramètres
      final uri = Uri.parse(baseUrlMRCalc).replace(queryParameters: params);
      
      // Envoi de la requête
      final response = await http.get(uri);
      
      // Vérification de la réponse
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la communication avec PVGIS MRCalc: $e');
    }
  }

  /// Convertit l'azimut de notre format (N=0°, E=90°, S=180°, W=270°) 
  /// au format PVGIS (S=0°, E=-90°, W=90°)
  static double convertAzimuthForAPI(double appAzimuth) {  // Removed underscore to make public
    // Notre app: N=0°, E=90°, S=180°, O=270°
    // PVGIS: S=0°, E=-90°, O=90°, N=±180°
    double pvgisAzimuth = appAzimuth - 180;
    
    // Assurer que l'angle est dans l'intervalle [-180, 180]
    if (pvgisAzimuth > 180) {
      pvgisAzimuth -= 360;
    } else if (pvgisAzimuth < -180) {
      pvgisAzimuth += 360;
    }
    
    return pvgisAzimuth;
  }
  
  /// Convertit les mesures d'ombre en valeurs d'horizon utilisables par l'API
  static List<double>? convertShadowMeasuresToHorizon(List<ShadowMeasurement>? measurements) {
    if (measurements == null || measurements.isEmpty) {
      return null;
    }
    
    // Trier les mesures par azimut
    final sortedMeasurements = List<ShadowMeasurement>.from(measurements)
      ..sort((a, b) => a.azimuth.compareTo(b.azimuth));
    
    // Créer une liste de 36 valeurs d'élévation à intervalle régulier (tous les 10°)
    final List<double> horizonValues = [];
    final int totalPoints = 36;
    final double step = 360 / totalPoints;
    
    // Fonction pour trouver la valeur d'élévation à un azimut donné par interpolation linéaire
    double getInterpolatedElevation(double targetAzimuth) {
      // Trouver les mesures avant et après l'azimut cible
      ShadowMeasurement? before;
      ShadowMeasurement? after;
      
      for (int i = 0; i < sortedMeasurements.length; i++) {
        if (sortedMeasurements[i].azimuth > targetAzimuth) {
          after = sortedMeasurements[i];
          if (i > 0) {
            before = sortedMeasurements[i - 1];
          } else {
            // Boucler à la dernière mesure si on est au début
            before = sortedMeasurements.last;
          }
          break;
        }
      }
      
      // Si on n'a pas trouvé de mesure après, c'est qu'on est après la dernière
      if (after == null) {
        after = sortedMeasurements.first;
        before = sortedMeasurements.last;
      }
      
      // Si on n'a pas trouvé de mesure avant, utiliser une valeur par défaut
      if (before == null) {
        return 0.0;
      }
      
      // Interpolation linéaire
      double beforeAz = before.azimuth;
      double afterAz = after.azimuth;
      
      // Si on traverse le Nord (0°/360°)
      if (afterAz - beforeAz > 180) {
        beforeAz += 360;
      } else if (beforeAz - afterAz > 180) {
        afterAz += 360;
      }
      
      // Si targetAzimuth est proche de 0 mais before est proche de 360
      if (targetAzimuth < 45 && beforeAz > 315) {
        targetAzimuth += 360;
      }
      
      double ratio = (targetAzimuth - beforeAz) / (afterAz - beforeAz);
      double elevation = before.elevation + ratio * (after.elevation - before.elevation);
      
      return max(0.0, elevation); // Now max is properly imported from dart:math
    }
    
    // Générer les 36 valeurs d'horizon
    for (int i = 0; i < totalPoints; i++) {
      double azimuth = i * step;  // 0°, 10°, 20°, ..., 350°
      double elevation = getInterpolatedElevation(azimuth);
      horizonValues.add(elevation);
    }
    
    return horizonValues;
  }
}
