import 'package:flutter/material.dart';
import 'user_service.dart';

class RoleGuard {
  // Wrapper pour les widgets qui nécessitent un certain rôle
  static Widget guardWidget({
    required Widget child,
    required List<UserRole> allowedRoles,
    Widget? fallbackWidget,
  }) {
    return FutureBuilder<UserRole>(
      future: UserService.getCurrentUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData && allowedRoles.contains(snapshot.data)) {
          return child;
        }
        
        // Widget de repli si l'utilisateur n'a pas le rôle requis
        return fallbackWidget ?? _buildDefaultFallbackWidget(context);
      },
    );
  }
  
  // Widget par défaut pour les utilisateurs sans autorisation
  static Widget _buildDefaultFallbackWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Accès non autorisé',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez mettre à niveau votre compte pour accéder à cette fonctionnalité',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigation vers l'écran de mise à niveau
              Navigator.of(context).pushNamed('/upgrade');
            },
            icon: const Icon(Icons.star),
            label: const Text('Mettre à niveau maintenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Vérifier si l'utilisateur peut accéder à une route
  static Future<bool> canAccessRoute(List<UserRole> allowedRoles) async {
    final role = await UserService.getCurrentUserRole();
    return allowedRoles.contains(role);
  }
}
