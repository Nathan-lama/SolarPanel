import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/roof_pan.dart';
import '../services/supabase_service.dart'; // Remplacer Firebase par Supabase
import 'orientation_screen.dart';
import 'inclination_screen.dart';
import 'obstacles_pan_screen.dart';
import 'peak_power_screen.dart';
import 'pan_analysis_screen.dart';

class PansListScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  
  const PansListScreen({
    super.key, 
    required this.latitude, 
    required this.longitude
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
  int _sendAttemptCount = 0;
  String _debugInfo = '';

  // Garder une trace de la dernière opération d'envoi réussie
  List<RoofPan>? _lastSentPans;

  // Variable pour stocker l'ID du projet le plus récent
  String? _lastProjectId;

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
        builder: (context) => const InclinationScreen(),
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
      _lastSentPans = null; // Reset sent status when adding a new pan
    });
  }

  // Méthode pour supprimer un pan
  void _deletePan(String id) {
    setState(() {
      _roofPans.removeWhere((pan) => pan.id == id);
      // Conserver l'ID du projet pour mise à jour plutôt que création
      // mais marquer que les pans ont changé
      _lastSentPans = null;
    });
  }

  // Méthode mise à jour pour envoyer les données à Supabase
  Future<void> _sendDataToSupabase() async {
    // Déboguer les appels multiples
    final now = DateTime.now();
    _sendAttemptCount++;
    
    developer.log(
      '[ENVOI_DEBUG] Tentative #$_sendAttemptCount - ${now.hour}:${now.minute}:${now.second}.${now.millisecond}',
      name: 'PanListScreen'
    );
    
    // Protection contre les clics rapides
    if (_lastSendAttempt != null && now.difference(_lastSendAttempt!).inSeconds < 2) {
      developer.log(
        '[ENVOI_DEBUG] Tentative ignorée - trop rapprochée (${now.difference(_lastSendAttempt!).inMilliseconds}ms)',
        name: 'PanListScreen'
      );
      return;
    }
    
    _lastSendAttempt = now;
    
    if (_roofPans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un pan de toit')),
      );
      return;
    }

    // Vérifier si ces pans ont déjà été envoyés exactement tels quels
    if (_lastSentPans != null && _arePansIdentical(_roofPans, _lastSentPans!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ces données ont déjà été envoyées. Modifiez un pan ou ajoutez-en un nouveau pour envoyer à nouveau.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _debugInfo = 'Début envoi: ${DateTime.now().toString().substring(11, 23)}';
    });
    
    try {
      // Créer un objet contenant toutes les informations avec le bon format
      final data = {
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'roof_pans': _roofPans.map((pan) {
          // S'assurer que toutes les clés nécessaires sont présentes
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
        // Ajout d'une clé pour détecter les mises à jour au même projet
        'update_to_project': _lastProjectId,
      };
      
      // Afficher les données pour le débogage
      developer.log('[DEBUG] Données à envoyer: $data', name: 'PanListScreen');
      
      // Envoyer les données à Supabase et récupérer l'ID du projet
      final projectId = await SupabaseService.saveRoofData(data, updateExisting: _lastProjectId != null);
      
      if (mounted) {
        setState(() {
          _lastSentPans = List.from(_roofPans);
          _lastProjectId = projectId;
          _debugInfo += '\nSuccès: ${DateTime.now().toString().substring(11, 23)}';
          _debugInfo += '\nID Projet: $projectId';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _lastProjectId != null ? 'Projet mis à jour avec succès' : 'Nouveau projet créé avec succès'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Amélioration de la gestion des erreurs pour le débogage
      String errorMessage = e.toString();
      
      developer.log('[ENVOI_DEBUG] Erreur: $errorMessage', name: 'PanListScreen', error: e);
      
      if (mounted) {
        setState(() => _debugInfo += '\nErreur: ${DateTime.now().toString().substring(11, 23)} - $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5), // Plus de temps pour lire l'erreur
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Vérifier si deux listes de pans sont identiques (comparaison améliorée)
  bool _arePansIdentical(List<RoofPan> list1, List<RoofPan> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      // Comparer les attributs importants
      if (list1[i].orientation != list2[i].orientation ||
          list1[i].inclination != list2[i].inclination ||
          list1[i].peakPower != list2[i].peakPower ||
          list1[i].hasObstacles != list2[i].hasObstacles) {
        return false;
      }
      
      // Comparer les mesures d'ombre si présentes
      final shadows1 = list1[i].shadowMeasurements;
      final shadows2 = list2[i].shadowMeasurements;
      
      if ((shadows1 == null) != (shadows2 == null)) {
        return false;
      }
      
      if (shadows1?.length != shadows2?.length) {
        return false;
      }
      
      // Comparaison détaillée des mesures d'ombres
      if (shadows1 != null && shadows2 != null) {
        for (int j = 0; j < shadows1.length; j++) {
          if (shadows1[j].azimuth != shadows2[j].azimuth || 
              shadows1[j].elevation != shadows2[j].elevation) {
            return false;
          }
        }
      }
    }
    
    return true;
  }
  
  // Reset l'état d'envoi lorsque l'utilisateur modifie les pans
  void _resetSentStatus() {
    if (_lastSentPans != null && !_arePansIdentical(_roofPans, _lastSentPans!)) {
      setState(() => _lastSentPans = null);
    }
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
          
          Padding(
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading 
                      ? null 
                      : (_lastSentPans != null && _arePansIdentical(_roofPans, _lastSentPans!))
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ces données ont déjà été envoyées'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        : _sendDataToSupabase,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : (_lastSentPans != null && _arePansIdentical(_roofPans, _lastSentPans!))
                        ? const Icon(Icons.check)
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isLoading 
                      ? 'Envoi en cours...' 
                      : (_lastSentPans != null && _arePansIdentical(_roofPans, _lastSentPans!))
                        ? 'Déjà envoyé'
                        : 'Envoyer les données'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_lastSentPans != null && _arePansIdentical(_roofPans, _lastSentPans!))
                        ? Colors.grey.shade600
                        : Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
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
