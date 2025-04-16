import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyProductionChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;
  
  const MonthlyProductionChart({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    // Créer la liste des BarChartGroupData pour chaque mois
    final List<BarChartGroupData> barGroups = [];
    
    // Obtenir les valeurs max pour l'échelle
    double maxY = 0;
    for (int i = 0; i < monthlyData.length; i++) {
      final data = monthlyData[i];
      final double value = data['E_m'] ?? 0.0;
      if (value > maxY) maxY = value;
    }
    
    // Arrondir maxY au multiple de 100 supérieur
    maxY = ((maxY ~/ 100) + 1) * 100;
    
    // Créer les barres pour chaque mois
    for (int i = 0; i < monthlyData.length; i++) {
      final data = monthlyData[i];
      final double value = data['E_m'] ?? 0.0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: Theme.of(context).colorScheme.primary,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Production Mensuelle (kWh)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final List<String> titles = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                          
                          if (value >= 0 && value < titles.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                titles[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
