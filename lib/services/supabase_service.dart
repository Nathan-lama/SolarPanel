import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

/// Service pour gérer les opérations avec Supabase
class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();
  
  // Référence à l'instance Supabase
  static SupabaseClient get client => Supabase.instance.client;
  
  // Constante pour le nom de la table - CORRIGÉ pour correspondre à votre structure
  static const String _tableName = 'solar_projects'; // Assurez-vous que cette table existe
  
  /// Initialise Supabase avec les clés d'API
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      developer.log('[SUPABASE] Initialisation de Supabase...', name: 'SupabaseService');
      
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true, // Activer le débogage pour voir les requêtes
      );
      
      developer.log('[SUPABASE] Initialisation réussie', name: 'SupabaseService');
    } catch (e) {
      developer.log('[SUPABASE] Erreur d\'initialisation: $e', name: 'SupabaseService', error: e);
      rethrow;
    }
  }

  /// Sauvegarde les données de toit dans la table Supabase
  static Future<void> saveRoofData(Map<String, dynamic> data) async {
    try {
      developer.log('[SUPABASE] Envoi des données...', name: 'SupabaseService');
      developer.log('[SUPABASE] Données: $data', name: 'SupabaseService');
      
      // Créer un nouveau projet
      final projectData = {
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'created_at': DateTime.now().toIso8601String(),
        'name': 'Projet ${DateTime.now().toString().substring(0, 10)}',
        // Ne pas inclure roof_pans ici car ils seront ajoutés séparément
      };
      
      // Insérer le projet et récupérer son ID
      final response = await client
          .from(_tableName)
          .insert(projectData)
          .select('id')
          .single();
      
      final projectId = response['id'];
      developer.log('[SUPABASE] Projet créé avec ID: $projectId', name: 'SupabaseService');
      
      // Maintenant insérer chaque pan de toit avec l'ID du projet
      final List<Map<String, dynamic>> roofPans = List<Map<String, dynamic>>.from(data['roof_pans']);
      
      for (final panData in roofPans) {
        // Préparer les données du pan
        final roofPanEntry = {
          'project_id': projectId,
          'peak_power': panData['peakPower'],
          'inclination': panData['inclination'],
          'orientation': panData['orientation'],
          'has_obstacles': panData['hasObstacles'] ?? false,
        };
        
        // Insérer le pan
        final panResponse = await client
            .from('roof_pans')
            .insert(roofPanEntry)
            .select('id')
            .single();
            
        final panId = panResponse['id'];
        developer.log('[SUPABASE] Pan créé avec ID: $panId', name: 'SupabaseService');
        
        // Insérer les mesures d'ombres si présentes
        if (panData.containsKey('shadowMeasurements') && 
            panData['shadowMeasurements'] != null && 
            panData['shadowMeasurements'] is List && 
            panData['shadowMeasurements'].isNotEmpty) {
          
          final shadowMeasurements = List<Map<String, dynamic>>.from(panData['shadowMeasurements']);
          
          for (final measurement in shadowMeasurements) {
            final measurementEntry = {
              'roof_pan_id': panId,
              'azimuth': measurement['azimuth'],
              'elevation': measurement['elevation'],
              // 'distance' peut être ajouté si disponible
            };
            
            await client.from('shadow_measurements').insert(measurementEntry);
          }
        }
      }
      
      developer.log('[SUPABASE] Données envoyées avec succès', name: 'SupabaseService');
      return;
    } catch (e) {
      developer.log('[SUPABASE] Erreur d\'envoi: $e', name: 'SupabaseService', error: e);
      
      // Fournir des détails sur l'erreur pour le débogage
      String errorMessage = 'Erreur lors de l\'envoi des données';
      
      if (e is PostgrestException) {
        errorMessage = 'Erreur Postgres ${e.code}: ${e.message}';
        developer.log('[SUPABASE] Détails PostgrestException: ${e.details}', name: 'SupabaseService');
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Récupère l'historique des données envoyées
  static Future<List<Map<String, dynamic>>> getRoofDataHistory() async {
    try {
      final response = await client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('[SUPABASE] Erreur de récupération: $e', name: 'SupabaseService', error: e);
      throw Exception('Erreur lors de la récupération des données: ${e.toString()}');
    }
  }
}
