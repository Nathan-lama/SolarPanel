import 'package:flutter/material.dart';
import '../models/roof_pan.dart';
import '../models/shadow_measurement.dart';
import '../services/html_to_pdf_service.dart';
import '../services/analysis_results_service.dart';
import '../services/pvgis_service.dart';
import 'pan_analysis_screen.dart';

class ClientDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> project;
  
  const ClientDetailsScreen({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    // Extraire les informations du projet
    final String projectName = project['name'] ?? 'Client sans nom';
    final String clientEmail = project['client_email'] ?? '';
    final String clientPhone = project['client_phone'] ?? '';
    final String clientAddress = project['client_address'] ?? '';
    final double latitude = (project['latitude'] ?? 0.0).toDouble();
    final double longitude = (project['longitude'] ?? 0.0).toDouble();
    final List<dynamic> roofPansData = project['roof_pans'] ?? [];
    
    // Convertir les données JSON en objets RoofPan
    final List<RoofPan> roofPans = roofPansData.map((panData) {
      // Convertir les mesures d'ombre si présentes
      List<ShadowMeasurement>? shadowMeasurements;
      if (panData['shadowMeasurements'] != null) {
        final List<dynamic> shadowData = panData['shadowMeasurements'];
        shadowMeasurements = shadowData.map((shadow) => ShadowMeasurement(
          azimuth: (shadow['azimuth'] ?? 0.0).toDouble(),
          elevation: (shadow['elevation'] ?? 0.0).toDouble(),
          timestamp: DateTime.now(), // Ajouter le paramètre timestamp requis
        )).toList();
      }
      
      return RoofPan(
        orientation: (panData['orientation'] ?? 0.0).toDouble(),
        inclination: (panData['inclination'] ?? 0.0).toDouble(),
        peakPower: (panData['peakPower'] ?? 0.0).toDouble(),
        hasObstacles: panData['hasObstacles'] ?? false,
        shadowMeasurements: shadowMeasurements,
      );
    }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pans de toit'),
        actions: [
          // Bouton de débogage (optionnel)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Informations du projet'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Client: $projectName'),
                        Text('Latitude: $latitude'),
                        Text('Longitude: $longitude'),
                        Text('Nombre de pans: ${roofPans.length}'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Affichage des informations client
          _buildClientInfoCard(projectName, clientEmail, clientPhone, clientAddress),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Pans de toit configurés',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          
          Expanded(
            child: roofPans.isEmpty
                ? _buildEmptyState()
                : _buildPansList(context, roofPans, latitude, longitude),
          ),
          
          // ABSENCE du bouton "Ajouter un pan" - c'est la différence principale
        ],
      ),
    );
  }
  
  // Widget pour afficher les informations client
  Widget _buildClientInfoCard(String name, String? email, String? phone, String? address) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client: $name',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (email != null && email.isNotEmpty)
              Text('Email: $email'),
            if (phone != null && phone.isNotEmpty)
              Text('Téléphone: $phone'),
            if (address != null && address.isNotEmpty)
              Text('Adresse: $address'),
          ],
        ),
      ),
    );
  }

  // Widget pour l'état vide (aucun pan)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.roofing,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun pan de toit configuré',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour télécharger le template PDF avec analyse automatique
  void _downloadPdfTemplate(BuildContext context, RoofPan pan, int panIndex) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Analyse et génération du PDF...'),
            ],
          ),
        ),
      );

      // Extraire les coordonnées du projet
      final double latitude = (project['latitude'] ?? 0.0).toDouble();
      final double longitude = (project['longitude'] ?? 0.0).toDouble();
      
      // Créer un ID unique pour le pan
      final String panId = 'pan_${panIndex}_${pan.orientation.toStringAsFixed(1)}_${pan.inclination.toStringAsFixed(1)}';
      
      // Vérifier si on a déjà des résultats d'analyse
      Map<String, dynamic>? analysisResults = await AnalysisResultsService.getAnalysisResults(panId);
      
      // Si pas de résultats, lancer l'analyse automatiquement
      if (analysisResults == null) {
        try {
          // Mettre à jour le message de chargement
          if (context.mounted) {
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Analyse PVGIS en cours...'),
                    SizedBox(height: 10),
                    Text(
                      'Récupération des données de production solaire',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Convertir les mesures d'ombre en valeurs d'horizon
          List<double>? horizonValues;
          if (pan.shadowMeasurements != null && pan.shadowMeasurements!.isNotEmpty) {
            horizonValues = PVGISService.convertShadowMeasuresToHorizon(pan.shadowMeasurements);
          }

          // Lancer l'analyse PVGIS avec votre service existant
          final pvgisResponse = await PVGISService.calculateProduction(
            latitude: latitude,
            longitude: longitude,
            roofPan: pan,
            horizonValues: horizonValues,
            systemLoss: 14.0,
          );

          // Formater et sauvegarder les résultats
          analysisResults = AnalysisResultsService.formatPvgisData(pvgisResponse);
          await AnalysisResultsService.saveAnalysisResults(panId, analysisResults);

        } catch (analysisError) {
          // En cas d'erreur d'analyse, utiliser les données par défaut
          debugPrint('Erreur lors de l\'analyse PVGIS : $analysisError');
          analysisResults = null;
        }
      }

      // Mettre à jour le message pour la génération PDF
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Génération du PDF...'),
              ],
            ),
          ),
        );
      }

      // Générer et télécharger le PDF avec les données
      await HtmlToPdfService.downloadTemplateAsPdf(
        roofPan: pan,
        latitude: latitude,
        longitude: longitude,
        analysisResults: analysisResults,
      );
      
      // Fermer le dialog de chargement
      if (context.mounted) {
        Navigator.pop(context);
        
        // Afficher un message de succès
        String message = 'PDF généré avec succès !';
        Color backgroundColor = Colors.green;
        
        if (analysisResults == null) {
          message = 'PDF généré avec données par défaut.\n(Erreur lors de l\'analyse PVGIS)';
          backgroundColor = Colors.orange;
        } else {
          message = 'PDF généré avec données d\'analyse réelles !';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );

        // Forcer la reconstruction pour mettre à jour l'indicateur d'analyse
        if (analysisResults != null) {
          (context as Element).markNeedsBuild();
        }
      }
    } catch (e) {
      // Fermer le dialog de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.pop(context);
        
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du PDF : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget pour afficher la liste des pans
  Widget _buildPansList(BuildContext context, List<RoofPan> roofPans, double latitude, double longitude) {
    return ListView.builder(
      itemCount: roofPans.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemBuilder: (context, index) {
        final pan = roofPans[index];
        final String panId = 'pan_${index}_${pan.orientation.toStringAsFixed(1)}_${pan.inclination.toStringAsFixed(1)}';
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${index + 1}'),
            ),
            title: Text('Pan ${index + 1}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pan.toString()),
                FutureBuilder<bool>(
                  future: AnalysisResultsService.hasAnalysisResults(panId),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return const Text(
                        '✓ Données d\'analyse disponibles',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return const Text(
                      '⚡ Analyse automatique lors du PDF',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  tooltip: 'Analyser ce pan',
                  onPressed: () => _navigateToPanAnalysis(context, pan, latitude, longitude, index),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Analyser et télécharger le rapport PDF',
                  onPressed: () => _downloadPdfTemplate(context, pan, index),
                ),
              ],
            ),
            onTap: () => _navigateToPanAnalysis(context, pan, latitude, longitude, index),
          ),
        );
      },
    );
  }

  // Navigation vers l'analyse d'un pan spécifique
  void _navigateToPanAnalysis(BuildContext context, RoofPan pan, double latitude, double longitude, int panIndex) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PanAnalysisScreen(
          roofPan: pan,
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
    
    // Rafraîchir l'affichage si des résultats ont été sauvegardés
    if (result == true && context.mounted) {
      // Force rebuild to update the analysis status
      (context as Element).markNeedsBuild();
    }
  }
}