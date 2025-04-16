import 'package:flutter/material.dart';
import '../models/roof_pan.dart';
import '../services/pvgis_service.dart';
import '../widgets/production/production_summary_widget.dart';
import '../widgets/production/monthly_production_widget.dart';
import '../widgets/production/system_losses_widget.dart';
import '../widgets/radiation/monthly_radiation_widget.dart';
import '../widgets/radiation/horizon_chart_widget.dart';

class ResultsScreen extends StatefulWidget {
  final List<RoofPan> roofPans;
  final double latitude;
  final double longitude;
  
  const ResultsScreen({
    super.key,
    required this.roofPans,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
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
      if (widget.roofPans.isEmpty) {
        throw Exception('Aucun pan de toit défini');
      }
      
      final RoofPan mainPan = widget.roofPans.first;
      final List<double>? horizonValues = PVGISService.convertShadowMeasuresToHorizon(
        mainPan.shadowMeasurements
      );
      
      final results = await Future.wait([
        PVGISService.calculateProduction(
          latitude: widget.latitude, 
          longitude: widget.longitude,
          roofPan: mainPan,
          horizonValues: horizonValues,
        ),
        PVGISService.getMonthlyRadiation(
          latitude: widget.latitude,
          longitude: widget.longitude,
          angle: mainPan.inclination,
          aspect: PVGISService.convertAzimuthForAPI(mainPan.orientation),
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
        title: const Text('Résultats'),
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
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductionSummaryWidget(
            roofPan: widget.roofPans.first,
            latitude: widget.latitude,
            longitude: widget.longitude,
            apiResults: _apiResults,
          ),
          const SizedBox(height: 24),
          MonthlyProductionWidget(apiResults: _apiResults),
          const SizedBox(height: 24),
          SystemLossesWidget(apiResults: _apiResults),
          const SizedBox(height: 24),
          MonthlyRadiationWidget(
            radiationResults: _radiationResults, 
            roofPan: widget.roofPans.first,
          ),
          const SizedBox(height: 24),
          HorizonChartWidget(
            roofPan: widget.roofPans.first,
            latitude: widget.latitude,
          ),
        ],
      ),
    );
  }
}
