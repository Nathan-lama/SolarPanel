import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:developer' as developer;

class AuthService {
  // Accès direct au client Supabase
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Inscription avec email et mot de passe
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      developer.log('[AUTH] Inscription effectuée: ${response.user?.id}', name: 'AuthService');
      return response;
    } catch (e) {
      developer.log('[AUTH] Erreur inscription: $e', name: 'AuthService', error: e);
      rethrow;
    }
  }
  
  // Connexion avec email et mot de passe
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      developer.log('[AUTH] Connexion réussie: ${response.user?.id}', name: 'AuthService');
      return response;
    } catch (e) {
      developer.log('[AUTH] Erreur connexion: $e', name: 'AuthService', error: e);
      rethrow;
    }
  }
  
  // Déconnexion
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      developer.log('[AUTH] Déconnexion réussie', name: 'AuthService');
    } catch (e) {
      developer.log('[AUTH] Erreur déconnexion: $e', name: 'AuthService', error: e);
      rethrow;
    }
  }
  
  // Réinitialisation du mot de passe
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      developer.log('[AUTH] Email de réinitialisation envoyé à: $email', name: 'AuthService');
    } catch (e) {
      developer.log('[AUTH] Erreur réinitialisation: $e', name: 'AuthService', error: e);
      rethrow;
    }
  }
  
  // Vérifier l'état d'authentification
  static bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }
  
  // Récupérer l'utilisateur actuel
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
  
  // Accès au flux d'état d'authentification
  static Stream<AuthState> get authStateChanges => 
      _supabase.auth.onAuthStateChange;
}
