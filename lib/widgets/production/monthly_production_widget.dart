import 'package:flutter/material.dart';

class MonthlyProductionWidget extends StatelessWidget {
  final Map<String, dynamic>? apiResults;

  const MonthlyProductionWidget({
    super.key,
    required this.apiResults,
  });

  @override
  Widget build(BuildContext context) {
    if (apiResults == null) return const SizedBox.shrink();
    
    final outputs = apiResults!['outputs'];
    final monthly = outputs?['monthly'];
    final fixedMonthly = monthly?['fixed'];
    
    if (fixedMonthly == null || fixedMonthly is! List) {
      return const SizedBox.shrink();
    }
    
    final monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    
    // Calculer la production annuelle totale
    double totalAnnualProduction = 0.0;
    for (var monthData in fixedMonthly) {
      if (monthData is Map && monthData['E_m'] != null) {
        totalAnnualProduction += monthData['E_m'];
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Production Mensuelle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Table des données mensuelles
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(1.5), // Mois
                1: FlexColumnWidth(2), // Production
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // En-tête de la table
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Mois', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Production (kWh)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                // Lignes de données
                for (var monthData in fixedMonthly)
                  if (monthData is Map && monthData['month'] != null && monthData['E_m'] != null)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(monthNames[monthData['month'] - 1]),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${monthData['E_m'].toStringAsFixed(2)} kWh'),
                        ),
                      ],
                    ),
                
                // Total annuel
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('TOTAL ANNUEL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${totalAnnualProduction.toStringAsFixed(2)} kWh',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
