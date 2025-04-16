import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyRadiationChart extends StatefulWidget {
  final List<Map<String, dynamic>> monthlyData;
  
  const MonthlyRadiationChart({
    super.key,
    required this.monthlyData,
  });

  @override
  State<MonthlyRadiationChart> createState() => _MonthlyRadiationChartState();
}

class _MonthlyRadiationChartState extends State<MonthlyRadiationChart> {
  int _selectedIndex = 0; // 0: H(h), 1: H(i_opt), 2: H(i)
  final List<String> _radiationTypes = ['H(h)', 'H(i_opt)', 'H(i)'];
  final List<String> _radiationLabels = [
    'Horizontal', 
    'Inclinaison optimale', 
    'Inclinaison spécifiée'
  ];
  final List<Color> _radiationColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    // Extraire la clé pour le type de radiation sélectionné
    final String dataKey = '${_radiationTypes[_selectedIndex]}_m';
    
    // Créer la liste des BarChartGroupData pour chaque mois
    final List<BarChartGroupData> barGroups = [];
    
    // Obtenir les valeurs max pour l'échelle
    double maxY = 0;
    for (int i = 0; i < widget.monthlyData.length; i++) {
      final data = widget.monthlyData[i];
      if (data.containsKey(dataKey)) {
        final double value = data[dataKey] ?? 0.0;
        if (value > maxY) maxY = value;
      }
    }
    
    // Arrondir maxY au multiple de 50 supérieur
    maxY = ((maxY ~/ 50) + 1) * 50;
    
    // Créer les barres pour chaque mois
    for (int i = 0; i < widget.monthlyData.length; i++) {
      final data = widget.monthlyData[i];
      final double value = data[dataKey] ?? 0.0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: _radiationColors[_selectedIndex],
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
            Row(
              children: [
                const Text(
                  'Irradiation Mensuelle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _selectedIndex,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedIndex = value;
                      });
                    }
                  },
                  items: [
                    for (int i = 0; i < _radiationTypes.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(_radiationLabels[i]),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'kWh/m² - ${_radiationLabels[_selectedIndex]}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
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
