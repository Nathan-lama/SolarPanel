import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/roof_pan.dart';
import '../models/shadow_measurement.dart';
import 'shadow_chart_screen.dart';

class ObstaclesPanScreen extends StatefulWidget {
  final double orientation;
  final double inclination;
  final double peakPower; // Nouvelle propriété pour la puissance crête
  
  const ObstaclesPanScreen({
    super.key, 
    required this.orientation,
    required this.inclination,
    required this.peakPower, // Ajouter le paramètre au constructeur
  });

  @override
  State<ObstaclesPanScreen> createState() => _ObstaclesPanScreenState();
}

class _ObstaclesPanScreenState extends State<ObstaclesPanScreen> {
  // Données des capteurs
  double _azimuth = 0.0;
  double _elevation = 0.0;
  
  // Liste des mesures
  final List<ShadowMeasurement> _measurements = [];
  
  // Abonnements aux capteurs
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Camera controller
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription>? _cameras;
  
  @override
  void initState() {
    super.initState();
    _initSensors();
    // Initialiser la caméra après un court délai pour s'assurer que le widget est monté
    Future.delayed(Duration.zero, _initCamera);
  }
  
  void _initSensors() {
    // Initialiser la boussole
    final compassEvents = FlutterCompass.events;
    if (compassEvents != null) {
      _compassSubscription = compassEvents.listen((CompassEvent event) {
        if (event.heading != null && mounted) {
          setState(() {
            _azimuth = event.heading!;
            // Convertir l'azimuth pour qu'il soit entre 0 et 360
            if (_azimuth < 0) _azimuth += 360;
          });
        }
      });
    }
    
    // Modifier la méthode de calcul de l'élévation
    // Utiliser accelerometerEventStream() au lieu de accelerometerEvents
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // Calcul amélioré de l'angle d'élévation à partir des données de l'accéléromètre
      // Formule modifiée pour une meilleure réponse quand on pointe vers le bas
      final double x = event.x;
      final double y = event.y;
      final double z = event.z;
      
      // Cette formule donne une élévation positive quand on pointe vers le haut
      // et négative quand on pointe vers le bas
      double pitch = atan2(z, sqrt(x * x + y * y)) * (180 / pi);
      
      // Inverser pour correspondre à la convention: positif vers le haut, négatif vers le bas
      pitch = -pitch;
      
      if (mounted) {
        setState(() {
          _elevation = pitch;
          // Ne limitons plus l'élévation entre 0 et 90, permettons les valeurs négatives
          // pour indiquer correctement quand on pointe sous l'horizon
        });
      }
    });
  }
  
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune caméra disponible')),
          );
        }
        return;
      }
      
      final CameraDescription camera = _cameras!.first;
      
      // Configurer la caméra avec des paramètres de base sans ajustements complexes
      final CameraController controller = CameraController(
        camera,
        ResolutionPreset.medium, // Utiliser une résolution moyenne pour un meilleur équilibre
        enableAudio: false,
      );
      
      await controller.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'initialisation de la caméra: $e')),
        );
      }
    }
  }
  
  void _addMeasurement() {
    final measurement = ShadowMeasurement(
      azimuth: _azimuth,
      elevation: _elevation,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _measurements.add(measurement);
    });
    
    // Suppression de la notification SnackBar pour ne pas gêner l'utilisation du bouton
    // La mise à jour visuelle de la liste des mesures est un feedback suffisant
  }
  
  Future<void> _exportToCsv() async {
    if (_measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune mesure à exporter')),
      );
      return;
    }
    
    // Format brut sans en-têtes ni annotations
    StringBuffer csvContent = StringBuffer();
    
    // Trier les mesures par azimut
    final sortedMeasurements = [..._measurements];
    sortedMeasurements.sort((a, b) => a.azimuth.compareTo(b.azimuth));
    
    // Ajouter uniquement les valeurs d'élévation
    for (var measurement in sortedMeasurements) {
      // Écrire uniquement la valeur d'élévation
      csvContent.writeln(measurement.elevation.toStringAsFixed(1));
    }
    
    // Sauvegarder dans un fichier temporaire
    final directory = await getTemporaryDirectory();
    final filename = 'horizon_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.csv';
    final path = '${directory.path}/$filename';
    final File file = File(path);
    await file.writeAsString(csvContent.toString());
    
    // Partager le fichier
    await Share.shareXFiles([XFile(path)], text: 'Données horizon');
  }
  
  void _viewChart() {
    if (_measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez des mesures pour générer un graphique')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShadowChartScreen(measurements: _measurements),
      ),
    );
  }
  
  void _finishAndReturn() {
    bool hasObstacles = _measurements.isNotEmpty;
    
    Navigator.pop(
      context,
      RoofPan(
        orientation: widget.orientation,
        inclination: widget.inclination,
        peakPower: widget.peakPower, // Ajouter la puissance PV
        hasObstacles: hasObstacles,
        shadowMeasurements: hasObstacles ? _measurements : null,
      ),
    );
  }
  
  @override
  void dispose() {
    _compassSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Barre supérieure avec bouton de retour
            _buildAppBar(),
            
            // Affichage des capteurs (azimut et élévation)
            _buildSensorOverlay(),
            
            // Vue caméra (maintenant sous les capteurs)
            Expanded(
              child: _buildCameraView(),
            ),
            
            // Liste des mesures
            _buildMeasurementsList(),
            
            // Boutons d'action
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }
  
  // Nouveau widget pour la vue caméra (qui était précédemment _buildCameraBackground)
  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Calculer la position verticale du point en fonction de l'élévation
    // Le point monte quand l'élévation est positive, descend quand négative
    const sensitivity = 4.0;
    final pointOffsetY = _elevation * sensitivity;
    final bool isPointingUp = _elevation > 0;
    
    return ClipRRect(
      // Arrondir les coins pour un aspect plus esthétique
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.black,
        child: Stack(
          children: [
            // Vue caméra
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),
            
            // Utiliser LayoutBuilder pour obtenir les dimensions de la zone de caméra
            LayoutBuilder(
              builder: (context, constraints) {
                // Centre vertical de cette zone de caméra
                final centerY = constraints.maxHeight / 2;
                
                return Stack(
                  children: [
                    // Ligne d'horizon fixe (ligne jaune)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: centerY,
                      child: Container(
                        height: 1.5,
                        color: Colors.yellow.withAlpha(179),
                      ),
                    ),
                    
                    // Point central qui se déplace selon l'élévation
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      left: constraints.maxWidth / 2 - 5,
                      top: centerY - pointOffsetY - 5,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isPointingUp ? Colors.red : Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                    
                    // Points cardinaux sur la ligne d'horizon
                    Positioned(
                      top: centerY - 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCardinalPoint('O', Colors.white),
                          _buildCardinalPoint('N', Colors.red),
                          _buildCardinalPoint('E', Colors.white),
                          _buildCardinalPoint('S', Colors.white),
                        ],
                      ),
                    ),
                    
                    // Lignes de repère pour l'élévation
                    Positioned(
                      left: 0,
                      right: 0,
                      top: centerY - 30 * sensitivity,
                      child: Container(
                        height: 1,
                        color: Colors.green.withAlpha(128),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              color: Colors.black.withAlpha(128),
                              child: const Text(
                                '+30°',
                                style: TextStyle(color: Colors.green, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    Positioned(
                      left: 0,
                      right: 0,
                      top: centerY + 30 * sensitivity,
                      child: Container(
                        height: 1,
                        color: Colors.red.withAlpha(128),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              color: Colors.black.withAlpha(128),
                              child: const Text(
                                '-30°',
                                style: TextStyle(color: Colors.red, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Affichage de débogage pour l'élévation
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(179),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Élév: ${_elevation.toStringAsFixed(1)}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Direction: ${_elevation > 0 ? "↑ HAUT" : "↓ BAS"}',
                              style: TextStyle(
                                color: _elevation > 0 ? Colors.red : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(179),
            Colors.transparent
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          
          const Expanded(
            child: Center(
              child: Text(
                'Mesure des masques d\'ombre',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.white),
            onPressed: _finishAndReturn,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSensorOverlay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSensorDisplay(
            "AZIMUT",
            "${_azimuth.toStringAsFixed(1)}°",
            Colors.blue,
            Icons.explore,
          ),
          
          // Remplacer le bouton de prise de mesure par le bouton Terminer ici
          GestureDetector(
            onTap: _finishAndReturn,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(230),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          
          _buildSensorDisplay(
            "ÉLÉVATION",
            "${_elevation.toStringAsFixed(1)}°",
            _elevation >= 0 ? Colors.orange : Colors.blue,
            Icons.trending_up,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSensorDisplay(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(153),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(179),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMeasurementsList() {
    if (_measurements.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(153),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Aucune mesure - Orientez votre téléphone vers les obstacles et appuyez sur le bouton vert pour les mesurer',
          style: TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(153),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Mesures enregistrées (${_measurements.length}):',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _measurements.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final measurement = _measurements[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _measurements.removeAt(index);
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white54,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Az: ${measurement.azimuth.toStringAsFixed(1)}°',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Él: ${measurement.elevation.toStringAsFixed(1)}°',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(204),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton "CSV" maintenant en première position
          _buildActionButton(
            'CSV',
            Icons.file_download,
            Colors.blueGrey.shade700,
            _exportToCsv,
          ),
          
          // Bouton "Mesurer" maintenant en deuxième position
          _buildActionButton(
            'Mesurer',
            Icons.add_location_alt,
            Colors.orange.shade700,
            _addMeasurement,
          ),
          
          _buildActionButton(
            'Graphique',
            Icons.pie_chart,
            Colors.blue.shade700,
            _viewChart,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardinalPoint(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
