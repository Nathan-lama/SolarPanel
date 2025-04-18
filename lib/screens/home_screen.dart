import 'package:flutter/material.dart';
import 'location_screen.dart';
import 'profile_screen.dart'; // Add this import

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              Column(
                children: [
                  // Logo centré
                  Icon(
                    Icons.solar_power,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 40),
                  
                  // Titre principal
                  Text(
                    "Bienvenue dans SolarPanel",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Phrase d'accroche
                  Text(
                    "Estimez votre production solaire en 2 minutes",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Informations sur les paramètres importants
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Paramètres à préparer:",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Les trois paramètres clés
                        _buildParameterRow(
                          context, 
                          "Puissance PV crête installée [kWp]",
                          Icons.electric_bolt,
                        ),
                        const SizedBox(height: 8),
                        _buildParameterRow(
                          context, 
                          "Inclinaison [°]",
                          Icons.rotate_right,
                        ),
                        const SizedBox(height: 8),
                        _buildParameterRow(
                          context, 
                          "Azimut (orientation)",
                          Icons.explore,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Bouton en bas
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Revenir à la navigation vers LocationScreen au lieu de InclinationScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LocationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Commencer",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper pour créer une ligne de paramètre avec icône
  Widget _buildParameterRow(BuildContext context, String text, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
