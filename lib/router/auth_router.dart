import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class AuthRouter {
  // Définition des routes et des rôles autorisés
  static final Map<String, List<UserRole>> _routePermissions = {
    '/home': [UserRole.admin, UserRole.paidUser, UserRole.freeUser],
    '/new_analysis': [UserRole.admin, UserRole.paidUser],
    '/client_details': [UserRole.admin, UserRole.paidUser],
    '/pdf_export': [UserRole.admin, UserRole.paidUser],
    '/analysis_history': [UserRole.admin, UserRole.paidUser],
    '/admin_panel': [UserRole.admin],
    '/upgrade': [UserRole.admin, UserRole.paidUser, UserRole.freeUser],
  };
  
  // Vérifier si l'utilisateur peut accéder à une route
  static Future<bool> canAccess(String routeName) async {
    // Si l'utilisateur n'est pas connecté, rediriger vers la connexion
    if (!AuthService.isAuthenticated()) {
      return false;
    }
    
    // Si la route n'est pas protégée, autoriser l'accès
    if (!_routePermissions.containsKey(routeName)) {
      return true;
    }
    
    final userRole = await UserService.getCurrentUserRole();
    return _routePermissions[routeName]!.contains(userRole);
  }
  
  // Rediriger l'utilisateur en fonction de son rôle
  static Future<String> getInitialRoute() async {
    if (!AuthService.isAuthenticated()) {
      return '/login';
    }
    
    final userRole = await UserService.getCurrentUserRole();
    
    switch (userRole) {
      case UserRole.admin:
        return '/home'; // ou '/admin_panel' si vous préférez
      case UserRole.paidUser:
        return '/home';
      case UserRole.freeUser:
        return '/upgrade'; // Rediriger vers la mise à niveau pour les utilisateurs gratuits
      default:
        return '/login';
    }
  }
  
  // Navigation avec contrôle d'accès
  static Future<void> navigateTo(BuildContext context, String routeName, {Object? arguments}) async {
    final hasAccess = await canAccess(routeName);
    
    if (hasAccess) {
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
    } else {
      // Si l'utilisateur n'a pas accès, rediriger vers la mise à niveau
      Navigator.of(context).pushNamed('/upgrade');
      
      // Afficher un message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez mettre à niveau votre compte pour accéder à cette fonctionnalité'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
