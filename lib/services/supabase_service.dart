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

  /// Sauvegarde les données de toit dans Supabase
  /// Retourne l'ID du projet créé ou mis à jour
  static Future<String> saveRoofData(Map<String, dynamic> data, {bool updateExisting = false}) async {
    try {
      developer.log('[SUPABASE] Envoi des données...', name: 'SupabaseService');
      
      String? existingProjectId = data['update_to_project'];
      data.remove('update_to_project'); // Enlever cette clé avant l'envoi
      
      String projectId;
      
      // Si c'est une mise à jour d'un projet existant
      if (updateExisting && existingProjectId != null) {
        developer.log('[SUPABASE] Mise à jour du projet existant: $existingProjectId', name: 'SupabaseService');
        
        // 1. Supprimer d'abord toutes les données associées à ce projet
        await _cleanProjectData(existingProjectId);
        
        // 2. Mettre à jour le projet principal
        final projectData = {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await client
            .from('solar_projects')
            .update(projectData)
            .eq('id', existingProjectId);
            
        projectId = existingProjectId;
      } 
      // Création d'un nouveau projet
      else {
        // Créer un nouveau projet
        final projectData = {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'created_at': DateTime.now().toIso8601String(),
          'name': 'Projet ${DateTime.now().toString().substring(0, 10)}',
        };
        
        // Insérer le projet et récupérer son ID
        final response = await client
            .from('solar_projects')
            .insert(projectData)
            .select('id')
            .single();
        
        projectId = response['id'];
        developer.log('[SUPABASE] Nouveau projet créé avec ID: $projectId', name: 'SupabaseService');
      }
      
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
            };
            
            await client.from('shadow_measurements').insert(measurementEntry);
          }
        }
      }
      
      developer.log('[SUPABASE] Données envoyées avec succès', name: 'SupabaseService');
      return projectId;
    } catch (e) {
      developer.log('[SUPABASE] Erreur d\'envoi: $e', name: 'SupabaseService', error: e);
      
      // Fournir un message d'erreur plus convivial
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
  
  /// Nettoie toutes les données associées à un projet 
  /// (pans de toit et mesures d'ombre) avant mise à jour
  static Future<void> _cleanProjectData(String projectId) async {
    try {
      // 1. Obtenir tous les pans associés à ce projet
      final panResponse = await client
          .from('roof_pans')
          .select('id')
          .eq('project_id', projectId);
      
      final List<Map<String, dynamic>> pans = List<Map<String, dynamic>>.from(panResponse);
      final List<String> panIds = pans.map((p) => p['id'] as String).toList();
      
      // 2. Supprimer toutes les mesures d'ombre associées à ces pans
      if (panIds.isNotEmpty) {
        await client
            .from('shadow_measurements')
            .delete()
            .filter('roof_pan_id', 'in', panIds);  // Correction: utiliser filter() au lieu de in()
      }
      
      // 3. Supprimer tous les pans associés à ce projet
      await client
          .from('roof_pans')
          .delete()
          .eq('project_id', projectId);
      
      developer.log('[SUPABASE] Nettoyage des données du projet $projectId réussi', 
                    name: 'SupabaseService');
    } catch (e) {
      developer.log('[SUPABASE] Erreur lors du nettoyage: $e', 
                    name: 'SupabaseService', 
                    error: e);
      // Ne pas relancer l'erreur pour ne pas interrompre le processus de mise à jour
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
