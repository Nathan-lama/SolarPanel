import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AnalysisResultsService {
  static const String _fileName = 'analysis_results.json';
  
  // Sauvegarder les résultats d'analyse
  static Future<void> saveAnalysisResults(String panId, Map<String, dynamic> results) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      Map<String, dynamic> allResults = {};
      
      // Charger les résultats existants s'ils existent
      if (await file.exists()) {
        final content = await file.readAsString();
        allResults = jsonDecode(content);
      }
      
      // Ajouter/mettre à jour les nouveaux résultats
      allResults[panId] = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': results,
      };
      
      // Sauvegarder
      await file.writeAsString(jsonEncode(allResults));
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des résultats : $e');
    }
  }
  
  // Récupérer les résultats d'analyse pour un pan
  static Future<Map<String, dynamic>?> getAnalysisResults(String panId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      if (!await file.exists()) {
        return null;
      }
      
      final content = await file.readAsString();
      final allResults = jsonDecode(content);
      
      return allResults[panId]?['data'];
    } catch (e) {
      return null;
    }
  }
  
  // Supprimer les résultats d'un pan
  static Future<void> deleteAnalysisResults(String panId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      if (!await file.exists()) {
        return;
      }
      
      final content = await file.readAsString();
      final allResults = jsonDecode(content);
      
      allResults.remove(panId);
      
      await file.writeAsString(jsonEncode(allResults));
    } catch (e) {
      throw Exception('Erreur lors de la suppression des résultats : $e');
    }
  }
  
  // Vérifier si des résultats existent pour un pan
  static Future<bool> hasAnalysisResults(String panId) async {
    final results = await getAnalysisResults(panId);
    return results != null;
  }
  
  // Formater les données PVGIS pour la sauvegarde (adapté à votre service existant)
  static Map<String, dynamic> formatPvgisData(Map<String, dynamic> pvgisResponse) {
    try {
      final outputs = pvgisResponse['outputs'];
      final monthly = outputs['monthly'] as List;
      final totals = outputs['totals'];
      
      // Extraire les données mensuelles avec conversion de type sécurisée
      final monthlyProduction = <double>[];
      final monthlyIrradiation = <double>[];
      final monthlyStdDev = <double>[];
      
      for (var month in monthly) {
        // Conversion sécurisée en double
        monthlyProduction.add(_toDouble(month['E_m']));
        monthlyIrradiation.add(_toDouble(month['H_i_m']));
        monthlyStdDev.add(_toDouble(month['SD_m']));
      }
      
      return {
        'monthlyProduction': monthlyProduction,
        'monthlyIrradiation': monthlyIrradiation,
        'monthlyStdDev': monthlyStdDev,
        'annualProduction': _toDouble(totals['fixed']['E_y']),
        'annualIrradiation': _toDouble(totals['fixed']['H_i_y']),
        'interannualVariability': _toDouble(totals['fixed']['SD_y']),
        'systemLosses': 14.0, // Valeur par défaut
        'incidenceAngleLoss': -2.86, // Valeurs par défaut basées sur PVGIS
        'spectralLoss': 1.43,
        'temperatureLoss': -7.1,
        'totalLosses': -21.28,
      };
    } catch (e) {
      throw Exception('Erreur lors du formatage des données PVGIS : $e');
    }
  }
  
  // Fonction utilitaire pour convertir de manière sécurisée en double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }
}
