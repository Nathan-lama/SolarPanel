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
  static Future<String> saveRoofData(Map<String, dynamic> data, {bool updateExisting = false}) async {
    try {
      // Filtrer les données pour ne garder que celles qui correspondent aux colonnes existantes
      final Map<String, dynamic> filteredData = {
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'name': data['name'],
        'user_id': data['user_id'],
        'roof_pans': data['roof_pans'],
      };
      
      // Ajouter les champs client seulement s'ils ont une valeur
      if (data['client_name'] != null) filteredData['client_name'] = data['client_name'];
      if (data['client_surname'] != null) filteredData['client_surname'] = data['client_surname'];
      if (data['client_email'] != null) filteredData['client_email'] = data['client_email'];
      if (data['client_phone'] != null) filteredData['client_phone'] = data['client_phone'];
      if (data['client_address'] != null) filteredData['client_address'] = data['client_address'];
      
      developer.log('[SUPABASE] Données filtrées à sauvegarder: $filteredData', name: 'SupabaseService');
      
      final response = await client
          .from(_tableName)
          .insert(filteredData)
          .select()
          .single();
      
      final projectId = response['id'].toString();
      developer.log('[SUPABASE] Données sauvegardées avec ID: $projectId', name: 'SupabaseService');
      
      return projectId;
    } catch (e) {
      developer.log('[SUPABASE] Erreur de sauvegarde: $e', name: 'SupabaseService', error: e);
      throw Exception('Erreur lors de la sauvegarde: ${e.toString()}');
    }
  }

  /// Récupère l'historique des données envoyées pour un utilisateur spécifique
  static Future<List<Map<String, dynamic>>> getUserProjects(String userId) async {
    try {
      developer.log('[SUPABASE] Récupération des projets pour l\'utilisateur: $userId', name: 'SupabaseService');
      
      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      developer.log('[SUPABASE] ${response.length} projets trouvés', name: 'SupabaseService');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('[SUPABASE] Erreur de récupération: $e', name: 'SupabaseService', error: e);
      throw Exception('Erreur lors de la récupération des données: ${e.toString()}');
    }
  }

  /// Récupère l'historique des données envoyées (toutes les données)
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
