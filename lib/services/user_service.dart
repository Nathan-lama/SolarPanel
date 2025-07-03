import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

enum UserRole {
  admin,
  paidUser,
  freeUser,
}

class UserService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Récupérer le rôle de l'utilisateur actuel
  static Future<UserRole> getCurrentUserRole() async {
    try {
      // Récupérer l'utilisateur actuel
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('[DEBUG] getCurrentUserRole: Aucun utilisateur connecté');
        return UserRole.freeUser; // Par défaut
      }
      
      debugPrint('[DEBUG] getCurrentUserRole: Utilisateur ID: ${user.id}');
      debugPrint('[DEBUG] getCurrentUserRole: Métadonnées: ${user.userMetadata}');
      
      // Récupérer le rôle depuis les métadonnées utilisateur
      final roleStr = user.userMetadata?['role'] as String? ?? 'free_user';
      debugPrint('[DEBUG] getCurrentUserRole: Role string trouvé: $roleStr');
      
      switch (roleStr) {
        case 'admin':
          return UserRole.admin;
        case 'paid_user':
          return UserRole.paidUser;
        default:
          return UserRole.freeUser;
      }
    } catch (e) {
      debugPrint('[ERREUR] getCurrentUserRole: $e');
      developer.log('[USER] Erreur lors de la récupération du rôle: $e', 
                   name: 'UserService', error: e);
      return UserRole.freeUser; // Rôle par défaut en cas d'erreur
    }
  }
  
  // Mettre à jour le rôle utilisateur avec les métadonnées Supabase
  static Future<void> setUserRole(UserRole role) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('[ERREUR] setUserRole: Aucun utilisateur connecté');
        throw Exception('Aucun utilisateur connecté');
      }
      
      debugPrint('[DEBUG] setUserRole: Mise à jour du rôle pour utilisateur: ${user.id}');
      debugPrint('[DEBUG] setUserRole: Métadonnées actuelles: ${user.userMetadata}');
      
      String roleStr;
      switch (role) {
        case UserRole.admin:
          roleStr = 'admin';
          break;
        case UserRole.paidUser:
          roleStr = 'paid_user';
          break;
        default:
          roleStr = 'free_user';
      }
      
      debugPrint('[DEBUG] setUserRole: Nouveau rôle: $roleStr');
      
      // Récupérer les métadonnées actuelles
      final currentMetadata = user.userMetadata ?? {};
      
      // Mettre à jour les métadonnées avec le nouveau rôle
      final updatedMetadata = {
        ...currentMetadata,
        'role': roleStr,
      };
      
      debugPrint('[DEBUG] setUserRole: Métadonnées mises à jour: $updatedMetadata');
      
      // Mettre à jour les métadonnées utilisateur
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: updatedMetadata),
      );
      
      debugPrint('[DEBUG] setUserRole: Réponse reçue de updateUser');
      debugPrint('[DEBUG] setUserRole: Utilisateur mis à jour: ${response.user?.id}');
      debugPrint('[DEBUG] setUserRole: Nouvelles métadonnées: ${response.user?.userMetadata}');
      
      developer.log('[USER] Rôle mis à jour pour l\'utilisateur: ${user.id}', 
                   name: 'UserService');
    } catch (e) {
      debugPrint('[ERREUR] setUserRole: $e');
      debugPrint('[ERREUR] setUserRole: Stack trace: ${StackTrace.current}');
      developer.log('[USER] Erreur lors de la mise à jour du rôle: $e', 
                   name: 'UserService', error: e);
      rethrow;
    }
  }
  
  // Initialiser les métadonnées lors de l'inscription
  static Future<void> initUserMetadata() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }
      
      // Vérifier si les métadonnées existent déjà
      final currentMetadata = user.userMetadata ?? {};
      if (currentMetadata.containsKey('role')) {
        return; // Les métadonnées existent déjà
      }
      
      // Initialiser les métadonnées avec le rôle par défaut
      final initialMetadata = {
        ...currentMetadata,
        'role': 'free_user',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Mettre à jour les métadonnées utilisateur
      await _supabase.auth.updateUser(
        UserAttributes(data: initialMetadata),
      );
      
      developer.log('[USER] Métadonnées initialisées pour l\'utilisateur: ${user.id}', 
                   name: 'UserService');
    } catch (e) {
      developer.log('[USER] Erreur lors de l\'initialisation des métadonnées: $e', 
                   name: 'UserService', error: e);
      rethrow;
    }
  }
  
  // Pour l'admin : mettre à jour le rôle d'un autre utilisateur (avec la fonction RPC)
  static Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté pour effectuer cette action');
      }
      
      // Vérifier d'abord si l'utilisateur actuel est admin
      final currentUserRole = await getCurrentUserRole();
      if (currentUserRole != UserRole.admin) {
        throw Exception('Permission refusée: Seuls les administrateurs peuvent modifier les rôles');
      }
      
      String roleStr;
      switch (role) {
        case UserRole.admin:
          roleStr = 'admin';
          break;
        case UserRole.paidUser:
          roleStr = 'paid_user';
          break;
        default:
          roleStr = 'free_user';
      }
      
      // Appeler une fonction RPC sur Supabase pour mettre à jour le rôle
      // Note: Cette fonction doit être créée dans Supabase
      await _supabase.rpc('update_user_role', params: {
        'target_user_id': userId,
        'new_role': roleStr,
      });
      
      developer.log('[USER] Rôle mis à jour pour l\'utilisateur: $userId', 
                   name: 'UserService');
    } catch (e) {
      developer.log('[USER] Erreur lors de la mise à jour du rôle: $e', 
                   name: 'UserService', error: e);
      rethrow;
    }
  }
  
  // Vérifier si l'utilisateur est un admin
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }
  
  // Vérifier si l'utilisateur est payant
  static Future<bool> isPaidUser() async {
    final role = await getCurrentUserRole();
    return role == UserRole.paidUser || role == UserRole.admin;
  }
}
