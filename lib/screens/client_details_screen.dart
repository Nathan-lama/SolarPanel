import 'package:flutter/material.dart';
import '../models/roof_pan.dart';
import '../models/shadow_measurement.dart';
import '../services/html_to_pdf_service.dart';
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

  // Widget pour afficher la liste des pans
  Widget _buildPansList(BuildContext context, List<RoofPan> roofPans, double latitude, double longitude) {
    return ListView.builder(
      itemCount: roofPans.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemBuilder: (context, index) {
        final pan = roofPans[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${index + 1}'),
            ),
            title: Text('Pan ${index + 1}'),
            subtitle: Text(pan.toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  tooltip: 'Analyser ce pan',
                  onPressed: () => _navigateToPanAnalysis(context, pan, latitude, longitude),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Télécharger le rapport PDF',
                  onPressed: () => _downloadPdfTemplate(context),
                ),
              ],
            ),
            onTap: () => _navigateToPanAnalysis(context, pan, latitude, longitude),
          ),
        );
      },
    );
  }

  // Navigation vers l'analyse d'un pan spécifique
  void _navigateToPanAnalysis(BuildContext context, RoofPan pan, double latitude, double longitude) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PanAnalysisScreen(
          roofPan: pan,
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
  }

  // Fonction pour télécharger le template PDF
  void _downloadPdfTemplate(BuildContext context) async {
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
              Text('Génération du PDF...'),
            ],
          ),
        ),
      );

      // Générer et télécharger le PDF
      await HtmlToPdfService.downloadTemplateAsPdf();
      
      // Fermer le dialog de chargement
      if (context.mounted) {
        Navigator.pop(context);
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF généré avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
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
}
