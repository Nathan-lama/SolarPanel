import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

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
  
  // Formater les données PVGIS pour la sauvegarde avec debug
  static Map<String, dynamic> formatPvgisData(Map<String, dynamic> pvgisResponse) {
    try {
      debugPrint('=== DEBUG PVGIS Response ===');
      debugPrint('Full response: $pvgisResponse');
      
      if (!pvgisResponse.containsKey('outputs')) {
        throw Exception('Pas de clé "outputs" dans la réponse PVGIS');
      }
      
      final outputs = pvgisResponse['outputs'];
      debugPrint('Outputs: $outputs');
      
      if (!outputs.containsKey('monthly')) {
        throw Exception('Pas de données mensuelles dans outputs');
      }
      
      final monthly = outputs['monthly'];
      debugPrint('Monthly structure: $monthly');
      
      // La structure PVGIS est: outputs.monthly.fixed (liste)
      if (!monthly.containsKey('fixed')) {
        throw Exception('Pas de données "fixed" dans monthly');
      }
      
      final monthlyFixed = monthly['fixed'] as List;
      debugPrint('Monthly fixed data count: ${monthlyFixed.length}');
      
      if (!outputs.containsKey('totals')) {
        throw Exception('Pas de totaux dans outputs');
      }
      
      final totals = outputs['totals'];
      debugPrint('Totals structure: $totals');
      
      // Extraire les données mensuelles avec debug
      final monthlyProduction = <double>[];
      final monthlyIrradiation = <double>[];
      final monthlyStdDev = <double>[];
      
      for (int i = 0; i < monthlyFixed.length; i++) {
        final month = monthlyFixed[i];
        debugPrint('Month $i: $month');
        
        final production = _toDouble(month['E_m']);
        final irradiation = _toDouble(month['H(i)_m']);
        final stdDev = _toDouble(month['SD_m']);
        
        monthlyProduction.add(production);
        monthlyIrradiation.add(irradiation);
        monthlyStdDev.add(stdDev);
        
        debugPrint('Month $i - Production: $production, Irradiation: $irradiation, StdDev: $stdDev');
      }
      
      // Extraire les totaux avec debug
      double annualProduction = 0.0;
      double annualIrradiation = 0.0;
      double interannualVariability = 0.0;
      
      if (totals.containsKey('fixed')) {
        final fixed = totals['fixed'];
        debugPrint('Fixed totals: $fixed');
        
        annualProduction = _toDouble(fixed['E_y']);
        annualIrradiation = _toDouble(fixed['H(i)_y']);
        interannualVariability = _toDouble(fixed['SD_y']);
      } else {
        debugPrint('Pas de données "fixed" dans totals');
      }
      
      // Extraire les pertes du système depuis les inputs
      double systemLosses = 14.0; // Valeur par défaut
      if (pvgisResponse.containsKey('inputs')) {
        final inputs = pvgisResponse['inputs'];
        if (inputs.containsKey('pv_module')) {
          final pvModule = inputs['pv_module'];
          systemLosses = _toDouble(pvModule['system_loss']) ?? 14.0;
        }
      }
      
      final result = {
        'monthlyProduction': monthlyProduction,
        'monthlyIrradiation': monthlyIrradiation,
        'monthlyStdDev': monthlyStdDev,
        'annualProduction': annualProduction,
        'annualIrradiation': annualIrradiation,
        'interannualVariability': interannualVariability,
        'systemLosses': systemLosses,
        'incidenceAngleLoss': -2.86, // Valeurs par défaut basées sur PVGIS
        'spectralLoss': 1.43,
        'temperatureLoss': -7.1,
        'totalLosses': -21.28,
      };
      
      debugPrint('=== Final formatted result ===');
      debugPrint('Annual production: $annualProduction');
      debugPrint('Annual irradiation: $annualIrradiation');
      debugPrint('Monthly production: $monthlyProduction');
      debugPrint('Monthly irradiation: $monthlyIrradiation');
      debugPrint('System losses: $systemLosses');
      
      return result;
    } catch (e) {
      debugPrint('Erreur lors du formatage des données PVGIS : $e');
      debugPrint('Response structure: $pvgisResponse');
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
