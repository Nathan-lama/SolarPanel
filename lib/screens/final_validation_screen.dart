import 'package:flutter/material.dart';

class FinalValidationScreen extends StatelessWidget {
  final Map<String, dynamic> panData;
  
  const FinalValidationScreen({
    super.key, 
    required this.panData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation finale'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récapitulatif des informations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Inclinaison du toit', panData['roofInclination']?.toString() ?? 'Non spécifiée'),
                    const Divider(),
                    _buildInfoRow('Obstacles détectés', panData['hasObstacles'] == true ? 'Oui' : 'Non'),
                    if (panData['hasObstacles'] == true && panData['obstaclesVideo'] != null)
                      _buildInfoRow('Vidéo d\'obstacles', 'Enregistrée'),
                    // Ajoutez d'autres informations selon votre modèle de données
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Logique pour finaliser et soumettre les données
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Données soumises avec succès!')),
                  );
                },
                child: const Text('Finaliser'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
