import 'package:flutter/material.dart';

class SystemLossesWidget extends StatelessWidget {
  final Map<String, dynamic>? apiResults;

  const SystemLossesWidget({
    super.key,
    required this.apiResults,
  });

  @override
  Widget build(BuildContext context) {
    if (apiResults == null) return const SizedBox.shrink();
    
    final outputs = apiResults!['outputs'];
    final losses = outputs?['losses'];
    
    if (losses == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pertes du Système',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Pertes diverses
            for (var entry in losses.entries)
              _buildInfoRow(
                _getLossLabel(entry.key), 
                '${entry.value.toStringAsFixed(2)}%',
                Icons.trending_down,
                Colors.red,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  String _getLossLabel(String key) {
    switch (key) {
      case 'string':
        return 'Pertes liées aux circuits';
      case 'angle_refl':
        return 'Pertes par angle d\'incidence et réflexion';
      case 'spectral':
        return 'Pertes spectrales';
      case 'temp':
        return 'Pertes thermiques';
      case 'shading':
        return 'Pertes liées aux ombrages';
      case 'wiring':
        return 'Pertes liées au câblage';
      case 'soiling':
        return 'Pertes liées à la saleté/poussière';
      case 'total':
        return 'Pertes totales';
      default:
        return key;
    }
  }
}
