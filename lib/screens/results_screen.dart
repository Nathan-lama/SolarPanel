import 'package:flutter/material.dart';
import '../models/roof_pan.dart';

class ResultsScreen extends StatelessWidget {
  final List<RoofPan> roofPans;

  const ResultsScreen({super.key, required this.roofPans});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats d\'analyse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyse de ${roofPans.length} pan${roofPans.length > 1 ? "s" : ""}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView.builder(
                itemCount: roofPans.length,
                itemBuilder: (context, index) {
                  final pan = roofPans[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pan ${index + 1}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.compass_calibration, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Orientation: ${pan.orientation.round()}°'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.line_axis, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Inclinaison: ${pan.inclination.round()}°'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Estimation de production: à implémenter',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logique pour générer un rapport détaillé
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonction à implémenter'),
                    ),
                  );
                },
                icon: const Icon(Icons.summarize),
                label: const Text('Générer un rapport détaillé'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
