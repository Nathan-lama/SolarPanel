import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/roof_pan.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import 'orientation_screen.dart';
import 'inclination_screen.dart' as inc_screen;
import 'obstacles_pan_screen.dart';
import 'peak_power_screen.dart';
import 'pan_analysis_screen.dart';

class PansListScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  
  // Ajouter les paramètres pour les informations client
  final String clientName;
  final String clientSurname;
  final String? clientEmail;
  final String? clientAddress;
  final String? clientPhone;
  
  const PansListScreen({
    super.key, 
    required this.latitude, 
    required this.longitude,
    required this.clientName,
    required this.clientSurname,
    this.clientEmail,
    this.clientAddress,
    this.clientPhone,
  });

  @override
  State<PansListScreen> createState() => _PansListScreenState();
}

class _PansListScreenState extends State<PansListScreen> {
  // Liste temporaire pour stocker les pans de toit
  final List<RoofPan> _roofPans = [];

  // Ajouter une variable pour gérer l'état de chargement
  bool _isLoading = false;

  // Variables pour le débogage
  DateTime? _lastSendAttempt;
  final int _sendAttemptCount = 0; // Rendu final car la valeur n'est jamais modifiée
  final String _debugInfo = ''; // Rendu final car la valeur n'est jamais modifiée

  // Méthode pour ajouter un nouveau pan
  Future<void> _addNewPan() async {
    // Navigation vers l'écran de puissance crête (nouveau)
    final double? peakPower = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (context) => const PeakPowerScreen(),
      ),
    );

    // Si l'utilisateur a annulé ou le widget n'est plus monté, on sort
    if (peakPower == null || !mounted) return;

    // Navigation vers l'écran d'orientation
    final double? orientation = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (context) => const OrientationScreen(),
      ),
    );

    // Si l'utilisateur a annulé ou le widget n'est plus monté, on sort
    if (orientation == null || !mounted) return;

    // Navigation vers l'écran d'inclinaison
    final double? inclination = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        // Use the updated prefix name
        builder: (context) => const inc_screen.InclinationScreen(),
      ),
    );

    // Si l'utilisateur a annulé ou le widget n'est plus monté, on sort
    if (inclination == null || !mounted) return;

    // Navigation vers l'écran des obstacles
    final RoofPan? newPan = await Navigator.push<RoofPan>(
      context,
      MaterialPageRoute(
        builder: (context) => ObstaclesPanScreen(
          orientation: orientation,
          inclination: inclination,
          peakPower: peakPower, // Ajouter la puissance PV
        ),
      ),
    );

    // Si l'utilisateur a annulé ou le widget n'est plus monté, on sort
    if (newPan == null || !mounted) return;

    // Ajout du nouveau pan à la liste
    setState(() {
      _roofPans.add(newPan);
    });
  }

  // Méthode pour supprimer un pan
  void _deletePan(String id) {
    setState(() {
      _roofPans.removeWhere((pan) => pan.id == id);
    });
  }

  // Navigation vers l'analyse d'un pan spécifique
  void _navigateToPanAnalysis(RoofPan pan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PanAnalysisScreen(
          roofPan: pan,
          latitude: widget.latitude,
          longitude: widget.longitude,
        ),
      ),
    );
  }

  // Méthode fusionnée pour envoyer les données et terminer l'analyse
  Future<void> _finishAnalysisAndSave() async {
    if (_roofPans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un pan de toit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtenir l'utilisateur actuel
      final currentUser = AuthService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('Vous devez être connecté pour sauvegarder une analyse');
      }

      // Créer un objet contenant toutes les informations avec le bon format
      final data = {
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'name': '${widget.clientName} ${widget.clientSurname}',
        'client_name': widget.clientName,
        'client_surname': widget.clientSurname,
        'client_email': widget.clientEmail,
        'client_phone': widget.clientPhone,
        'user_id': currentUser.id,
        'roof_pans': _roofPans.map((pan) {
          return {
            'peakPower': pan.peakPower,
            'inclination': pan.inclination,
            'orientation': pan.orientation,
            'hasObstacles': pan.hasObstacles,
            'shadowMeasurements': pan.shadowMeasurements?.map((measurement) => {
              'azimuth': measurement.azimuth,
              'elevation': measurement.elevation,
            }).toList() ?? [],
          };
        }).toList(),
      };

      developer.log('[PANS_LIST] Sauvegarde des données: $data', name: 'PansListScreen');

      // Envoyer à Supabase
      final projectId = await SupabaseService.saveRoofData(data);
      
      developer.log('[PANS_LIST] Projet sauvegardé avec ID: $projectId', name: 'PansListScreen');

      // Vérification du montage avant d'utiliser le BuildContext
      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analyse sauvegardée avec succès ! ID: $projectId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Attendre un peu pour que le message soit visible
      await Future.delayed(const Duration(seconds: 1));

      // Nouvelle vérification du montage après attente
      if (!mounted) return;

      // Retourner au tableau de bord (écran d'accueil)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      developer.log('[PANS_LIST] Erreur de sauvegarde: $e', name: 'PansListScreen', error: e);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pans de toit'),
        actions: [
          // Bouton de débogage
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Informations de débogage'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tentatives d\'envoi: $_sendAttemptCount'),
                        Text('Dernier envoi: ${_lastSendAttempt?.toString() ?? "Aucun"}'),
                        Text('État de chargement: ${_isLoading ? "En cours" : "Inactif"}'),
                        const Divider(),
                        Text(_debugInfo),
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
          _buildClientInfoCard(),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Configurez les pans de votre toit',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          
          Expanded(
            child: _roofPans.isEmpty
                ? _buildEmptyState()
                : _buildPansList(),
          ),
          
          // Boutons d'action mis à jour
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  // Nouveau widget pour afficher les informations client
  Widget _buildClientInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client: ${widget.clientName} ${widget.clientSurname}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (widget.clientEmail != null && widget.clientEmail!.isNotEmpty)
              Text('Email: ${widget.clientEmail}'),
            if (widget.clientPhone != null && widget.clientPhone!.isNotEmpty)
              Text('Téléphone: ${widget.clientPhone}'),
            if (widget.clientAddress != null && widget.clientAddress!.isNotEmpty)
              Text('Adresse: ${widget.clientAddress}'),
          ],
        ),
      ),
    );
  }

  // Refactorisation des boutons d'action en bas d'écran
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _addNewPan,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un pan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bouton fusionné "Terminer l'analyse"
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _finishAnalysisAndSave,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
              label: Text(_isLoading 
                ? 'Sauvegarde en cours...' 
                : 'Terminer l\'analyse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ),
        ],
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
          const SizedBox(height: 8),
          Text(
            'Ajoutez un pan pour commencer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher la liste des pans
  Widget _buildPansList() {
    return ListView.builder(
      itemCount: _roofPans.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemBuilder: (context, index) {
        final pan = _roofPans[index];
        return Dismissible(
          key: Key(pan.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _deletePan(pan.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pan ${index + 1} supprimé'),
              ),
            );
          },
          child: Card(
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
                    onPressed: () => _navigateToPanAnalysis(pan),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Supprimer ce pan',
                    onPressed: () => _deletePan(pan.id),
                  ),
                ],
              ),
              onTap: () => _navigateToPanAnalysis(pan),
            ),
          ),
        );
      },
    );
  }
}
