import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/roof_pan.dart';

class ProductionSummaryWidget extends StatelessWidget {
  final RoofPan roofPan;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? apiResults;

  const ProductionSummaryWidget({
    super.key,
    required this.roofPan,
    required this.latitude,
    required this.longitude,
    required this.apiResults,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultsHeader(context),
        const SizedBox(height: 16),
        _buildTotalProduction(context),
      ],
    );
  }

  Widget _buildResultsHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résultats de la production PV',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Localisation: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configuration du pan:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Puissance: ${roofPan.peakPower} kWp',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Inclinaison: ${roofPan.inclination.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Orientation: ${roofPan.orientation.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Masques d\'ombre: ${roofPan.hasObstacles ? "Oui" : "Non"}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTotalProduction(BuildContext context) {
    if (apiResults == null) return const SizedBox.shrink();
    
    final outputs = apiResults!['outputs'];
    final totals = outputs?['totals'];
    
    if (totals == null) {
      return const SizedBox.shrink();
    }
    
    // Correctly use NumberFormat from the intl package
    final formatter = NumberFormat("#,##0.00", "fr_FR");
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Production annuelle
            if (totals['E_y'] != null) ...[
              _buildInfoRow(
                'Production annuelle', 
                '${formatter.format(totals['E_y'])} kWh',
                Icons.bolt,
                Colors.amber,
              ),
            ],
            
            // Production journalière moyenne
            if (totals['E_d'] != null) ...[
              _buildInfoRow(
                'Production quotidienne moyenne', 
                '${formatter.format(totals['E_d'])} kWh',
                Icons.calendar_today,
                Colors.blue,
              ),
            ],
            
            // Production mensuelle moyenne
            if (totals['E_m'] != null) ...[
              _buildInfoRow(
                'Production mensuelle moyenne', 
                '${formatter.format(totals['E_m'])} kWh',
                Icons.date_range,
                Colors.green,
              ),
            ],
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
}
