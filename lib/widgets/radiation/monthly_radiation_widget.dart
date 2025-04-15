import 'package:flutter/material.dart';
import '../../models/roof_pan.dart';

class MonthlyRadiationWidget extends StatelessWidget {
  final Map<String, dynamic>? radiationResults;
  final RoofPan roofPan;

  const MonthlyRadiationWidget({
    super.key,
    required this.radiationResults,
    required this.roofPan,
  });

  @override
  Widget build(BuildContext context) {
    if (radiationResults == null || 
        !radiationResults!.containsKey('outputs') || 
        !radiationResults!['outputs'].containsKey('monthly')) {
      return const SizedBox.shrink();
    }
    
    final monthlyData = radiationResults!['outputs']['monthly'];
    if (monthlyData is! List || monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Find the latest year
    int? lastYear;
    for (var item in monthlyData) {
      if (item is Map && item.containsKey('year')) {
        final int year = item['year'];
        if (lastYear == null || year > lastYear) {
          lastYear = year;
        }
      }
    }
    
    if (lastYear == null) {
      return const SizedBox.shrink();
    }
    
    // Filter for the latest year and sort by month
    final lastYearData = monthlyData
        .where((item) => item is Map && item['year'] == lastYear)
        .toList()
      ..sort((a, b) => (a['month'] as int).compareTo(b['month'] as int));
    
    final monthNames = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    
    // Calculate yearly totals
    double totalH = 0;
    double totalIOpt = 0;
    double totalI = 0;
    
    for (var item in lastYearData) {
      totalH += item['H(h)_m'] ?? 0;
      totalIOpt += item['H(i_opt)_m'] ?? 0;
      totalI += item['H(i)_m'] ?? 0;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Irradiation Mensuelle $lastYear',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan incliné à ${roofPan.inclination.toStringAsFixed(1)}° et orienté à ${roofPan.orientation.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                columns: const [
                  DataColumn(label: Text('Mois')),
                  DataColumn(label: Text('H(h)\n[kWh/m²]')),
                  DataColumn(label: Text('H(i_opt)\n[kWh/m²]')),
                  DataColumn(label: Text('H(i)\n[kWh/m²]')),
                ],
                rows: [
                  // Monthly rows
                  for (var item in lastYearData)
                    DataRow(cells: [
                      DataCell(Text(monthNames[item['month'] - 1])),
                      DataCell(Text((item['H(h)_m'] ?? 0).toStringAsFixed(1))),
                      DataCell(Text((item['H(i_opt)_m'] ?? 0).toStringAsFixed(1))),
                      DataCell(Text((item['H(i)_m'] ?? 0).toStringAsFixed(1))),
                    ]),
                  
                  // Yearly total
                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey.shade200),
                    cells: [
                      const DataCell(Text('ANNÉE', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(totalH.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(totalIOpt.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(totalI.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Légende:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• H(h) : Irradiation sur plan horizontal'),
            const Text('• H(i_opt): Irradiation sur plan à inclinaison optimale'),
            const Text('• H(i) : Irradiation sur plan incliné spécifié'),
          ],
        ),
      ),
    );
  }
}
