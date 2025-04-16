import 'package:flutter/material.dart';
import '../models/roof_pan.dart';
import '../services/pvgis_service.dart';
import '../widgets/production/production_summary_widget.dart';
import '../widgets/production/monthly_production_widget.dart';
import '../widgets/production/system_losses_widget.dart';
import '../widgets/radiation/monthly_radiation_widget.dart';
import '../widgets/radiation/horizon_chart_widget.dart';
import '../widgets/charts/monthly_production_chart.dart';
import '../widgets/charts/monthly_radiation_chart.dart';

class PanAnalysisScreen extends StatefulWidget {
  final RoofPan roofPan;
  final double latitude;
  final double longitude;
  
  const PanAnalysisScreen({
    super.key,
    required this.roofPan,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PanAnalysisScreen> createState() => _PanAnalysisScreenState();
}

class _PanAnalysisScreenState extends State<PanAnalysisScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _apiResults;
  Map<String, dynamic>? _radiationResults;
  
  @override
  void initState() {
    super.initState();
    _fetchPVGISData();
  }
  
  Future<void> _fetchPVGISData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Convertir les mesures d'ombre en valeurs d'horizon pour l'API
      final List<double>? horizonValues = PVGISService.convertShadowMeasuresToHorizon(
        widget.roofPan.shadowMeasurements
      );
      
      // Appels parallèles aux APIs PVGIS
      final results = await Future.wait([
        // Appel à l'API PVCalc pour les calculs de production PV
        PVGISService.calculateProduction(
          latitude: widget.latitude, 
          longitude: widget.longitude,
          roofPan: widget.roofPan,
          horizonValues: horizonValues,
        ),
        
        // Appel à l'API MRCalc pour les données de radiation solaire
        PVGISService.getMonthlyRadiation(
          latitude: widget.latitude,
          longitude: widget.longitude,
          angle: widget.roofPan.inclination,
          aspect: PVGISService.convertAzimuthForAPI(widget.roofPan.orientation),
          horizonValues: horizonValues,
        )
      ]);
      
      setState(() {
        _apiResults = results[0];
        _radiationResults = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analyse du Pan ${widget.roofPan.toString().substring(0, 20)}...'),
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Calcul en cours...\nCette opération peut prendre quelques instants'),
          ],
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPVGISData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    // Extraire les données de production mensuelle pour le graphique
    List<Map<String, dynamic>> monthlyProductionData = [];
    if (_apiResults != null && 
        _apiResults!.containsKey('outputs') && 
        _apiResults!['outputs'].containsKey('monthly') &&
        _apiResults!['outputs']['monthly'].containsKey('fixed')) {
      
      monthlyProductionData = List<Map<String, dynamic>>.from(_apiResults!['outputs']['monthly']['fixed']);
    }
    
    // Extraire les données de radiation mensuelle pour le graphique
    List<Map<String, dynamic>> monthlyRadiationData = [];
    if (_radiationResults != null && 
        _radiationResults!.containsKey('outputs') && 
        _radiationResults!['outputs'].containsKey('monthly')) {
      
      final monthlyData = _radiationResults!['outputs']['monthly'];
      if (monthlyData is List && monthlyData.isNotEmpty) {
        int? lastYear;
        for (var item in monthlyData) {
          if (item is Map && item.containsKey('year')) {
            final int year = item['year'];
            if (lastYear == null || year > lastYear) {
              lastYear = year;
            }
          }
        }
        
        if (lastYear != null) {
          monthlyRadiationData = monthlyData
            .where((item) => item is Map && item['year'] == lastYear)
            .map((item) => item as Map<String, dynamic>) // Add explicit cast here
            .toList()
            ..sort((a, b) => (a['month'] as int).compareTo(b['month'] as int));
        }
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanInfoCard(),
          const SizedBox(height: 24),
          
          // Graphique à barres pour la production mensuelle
          if (monthlyProductionData.isNotEmpty) ...[
            MonthlyProductionChart(monthlyData: monthlyProductionData),
            const SizedBox(height: 24),
          ],
          
          // Widget de résumé de production
          ProductionSummaryWidget(
            roofPan: widget.roofPan,
            latitude: widget.latitude,
            longitude: widget.longitude,
            apiResults: _apiResults,
          ),
          const SizedBox(height: 24),
          
          // Widget de détail de production mensuelle
          MonthlyProductionWidget(apiResults: _apiResults),
          const SizedBox(height: 24),
          
          // Graphique à barres pour la radiation mensuelle
          if (monthlyRadiationData.isNotEmpty) ...[
            MonthlyRadiationChart(monthlyData: monthlyRadiationData),
            const SizedBox(height: 24),
          ],
          
          // Widget de détail des radiations mensuelles
          MonthlyRadiationWidget(
            radiationResults: _radiationResults, 
            roofPan: widget.roofPan,
          ),
          const SizedBox(height: 24),
          
          // Widget des pertes du système
          SystemLossesWidget(apiResults: _apiResults),
          const SizedBox(height: 24),
          
          // Widget du graphique d'horizon
          HorizonChartWidget(
            roofPan: widget.roofPan,
            latitude: widget.latitude,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPanInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration du Pan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.power,
                    label: 'Puissance',
                    value: '${widget.roofPan.peakPower} kWp',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.rotate_90_degrees_ccw,
                    label: 'Inclinaison',
                    value: '${widget.roofPan.inclination.toStringAsFixed(1)}°',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.compass_calibration,
                    label: 'Orientation',
                    value: '${widget.roofPan.orientation.toStringAsFixed(1)}°',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.terrain,
                    label: 'Obstacles',
                    value: widget.roofPan.hasObstacles ? 'Présents' : 'Aucun',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
