import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'clients_list_screen.dart';
import 'new_analysis_screen.dart'; // Importer le nouvel écran

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête avec logo
                _buildHeader(context),
                
                const SizedBox(height: 32),
                
                // Section des actions principales
                _buildMainActions(context),
                
                const SizedBox(height: 40),
                
                // Section statistiques rapides (placeholder)
                _buildQuickStats(context),
                
                const SizedBox(height: 30),
                
                // Section informations/conseils
                _buildInfoSection(context),
              ],
            ),
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
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        // Titre et sous-titre
        Text(
          "Tableau de bord SolarPanel",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Gérez vos projets solaires en quelques clics",
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            "Que souhaitez-vous faire ?",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Carte pour nouvelle analyse - Modifier pour aller vers NewAnalysisScreen
        _buildActionCard(
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
        const SizedBox(height: 16),
        // Carte pour voir les clients
        _buildActionCard(
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
        _buildActionCard(
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
  
  // Carte d'action cliquable
  Widget _buildActionCard(
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
        side: BorderSide(color: color.withAlpha(51), width: 1), // Remplacé withOpacity(0.2) par withAlpha(51)
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26), // Remplacé withOpacity(0.1) par withAlpha(26)
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
  
  // Statistiques rapides
  Widget _buildQuickStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            "Aperçu",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            _buildStatCard(
              context,
              icon: Icons.analytics,
              value: "12",
              label: "Analyses",
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              context,
              icon: Icons.person,
              value: "5",
              label: "Clients",
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              context,
              icon: Icons.architecture,
              value: "8",
              label: "Toits",
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }
  
  // Carte de statistique
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(26), // Remplacé withOpacity(0.1) par withAlpha(26)
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(51)), // Remplacé withOpacity(0.2) par withAlpha(51)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  // Section d'informations
  Widget _buildInfoSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Le saviez-vous ?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Une orientation sud avec une inclinaison de 30-35° est généralement optimale pour les panneaux solaires en Europe.",
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // À implémenter - page d'astuces
                },
                child: const Text("Plus d'astuces"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
