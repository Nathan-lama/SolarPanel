import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'clients_list_screen.dart';
import 'new_analysis_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../router/auth_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SolarPanel'),
        actions: [
          // Bouton pour accéder au panneau d'administration (uniquement pour les admins)
          FutureBuilder<bool>(
            future: UserService.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              
              final isAdmin = snapshot.data ?? false;
              if (isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Panneau d\'administration',
                  onPressed: () {
                    // Navigation vers le panneau d'admin
                    AuthRouter.navigateTo(context, '/admin_panel');
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Menu utilisateur
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } else if (value == 'upgrade') {
                AuthRouter.navigateTo(context, '/upgrade');
              } else if (value == 'profile') {
                // Naviguer vers le profil
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Mon profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'upgrade',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('Statut Premium'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<UserRole>(
        future: UserService.getCurrentUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userRole = snapshot.data ?? UserRole.freeUser;
          
          // Affichage pour les utilisateurs gratuits
          if (userRole == UserRole.freeUser) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fonctionnalités limitées',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Passez à la version premium pour débloquer toutes les fonctionnalités de l\'application',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => AuthRouter.navigateTo(context, '/upgrade'),
                    icon: const Icon(Icons.star),
                    label: const Text('Mettre à niveau'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Affichage pour les utilisateurs payants et admins
          return const YourExistingHomeContent();
        },
      ),
      
      // Bouton FAB uniquement pour les utilisateurs payants et admins
      floatingActionButton: FutureBuilder<bool>(
        future: UserService.isPaidUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          
          final isPaid = snapshot.data ?? false;
          if (isPaid) {
            return FloatingActionButton.extended(
              onPressed: () => AuthRouter.navigateTo(context, '/new_analysis'),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle analyse'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// Extrait du contenu existant du HomeScreen
class YourExistingHomeContent extends StatelessWidget {
  const YourExistingHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Votre contenu existant pour les utilisateurs payants
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Nouvelle analyse - carte principale plus grande
        _buildPrimaryActionCard(
          context,
          icon: Icons.add_chart,
          title: "Nouvelle analyse",
          subtitle: "Calculer la production d'une nouvelle installation",
          color: Theme.of(context).colorScheme.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewAnalysisScreen()),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Carte pour voir les clients
        _buildSecondaryActionCard(
          context,
          icon: Icons.people,
          title: "Mes clients",
          subtitle: "Gérer vos clients et leurs projets",
          color: Theme.of(context).colorScheme.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClientsListScreen()),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Carte pour historique des analyses
        _buildSecondaryActionCard(
          context,
          icon: Icons.history,
          title: "Historique des analyses",
          subtitle: "Consulter vos analyses précédentes",
          color: Colors.teal,
          onTap: () {
            // À implémenter plus tard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fonctionnalité à venir')),
            );
          },
        ),
      ],
    );
  }
  
  // Carte d'action principale plus grande et visible
  Widget _buildPrimaryActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Carte d'action secondaire
  Widget _buildSecondaryActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
