import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'clients_list_screen.dart';
import 'new_analysis_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SolarPanel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête avec logo
              _buildHeader(context),
              
              const SizedBox(height: 40),
              
              // Section des actions principales - occupant tout l'espace disponible
              Expanded(
                child: _buildMainActions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Section d'en-tête
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo
        Icon(
          Icons.solar_power,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        // Titre et sous-titre
        Text(
          "SolarPanel",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Gérez vos projets solaires simplement",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  
  // Section des actions principales avec les boutons
  Widget _buildMainActions(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
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
