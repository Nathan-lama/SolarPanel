import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../models/roof_pan.dart';
import '../models/shadow_measurement.dart';
import 'shadow_chart_screen.dart';

class ObstaclesPanScreen extends StatefulWidget {
  final double orientation;
  final double inclination;
  
  const ObstaclesPanScreen({
    super.key, 
    required this.orientation,
    required this.inclination,
  });

  @override
  State<ObstaclesPanScreen> createState() => _ObstaclesPanScreenState();
}

class _ObstaclesPanScreenState extends State<ObstaclesPanScreen> {
  // Données des capteurs
  double _azimuth = 0.0;
  double _elevation = 0.0;
  bool _hasCompass = false;
  
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
    _checkCompassAvailability();
    _initSensors();
    // Initialiser la caméra après un court délai pour s'assurer que le widget est monté
    Future.delayed(Duration.zero, _initCamera);
  }
  
  void _checkCompassAvailability() async {
    _hasCompass = await FlutterCompass.events != null;
    if (mounted) setState(() {});
  }
  
  void _initSensors() {
    // Initialiser la boussole
    if (FlutterCompass.events != null) {
      _compassSubscription = FlutterCompass.events!.listen((CompassEvent event) {
        if (event.heading != null && mounted) {
          setState(() {
            _azimuth = event.heading!;
            // Convertir l'azimuth pour qu'il soit entre 0 et 360
            if (_azimuth < 0) _azimuth += 360;
          });
        }
      });
    }
    
    // Initialiser l'accéléromètre pour calculer l'angle d'élévation
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // Calcul de l'angle d'inclinaison à partir des données de l'accéléromètre
      final double x = event.x;
      final double y = event.y;
      final double z = event.z;
      
      // Calculer l'angle d'élévation (pitch)
      double pitch = atan2(-x, sqrt(y * y + z * z)) * (180 / pi);
      
      if (mounted) {
        setState(() {
          _elevation = pitch;
          // Assurer que l'élévation est entre 0 et 90
          _elevation = _elevation.clamp(0.0, 90.0);
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mesure ajoutée: Azimut ${_azimuth.toStringAsFixed(1)}°, Élévation ${_elevation.toStringAsFixed(1)}°'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }
  
  Future<void> _exportToCsv() async {
    if (_measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune mesure à exporter')),
      );
      return;
    }
    
    // Préparer les données CSV
    List<List<dynamic>> rows = [];
    rows.add(ShadowMeasurement.csvHeaders());
    rows.addAll(_measurements.map((m) => m.toCsvRow()));
    
    String csv = const ListToCsvConverter().convert(rows);
    
    // Sauvegarder dans un fichier temporaire
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/masques_ombre_${DateTime.now().millisecondsSinceEpoch}.csv';
    final File file = File(path);
    await file.writeAsString(csv);
    
    // Partager le fichier
    await Share.shareXFiles([XFile(path)], text: 'Mesures de masques d\'ombre');
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond noir pour éviter les espaces vides si la caméra ne remplit pas tout l'écran
          Container(color: Colors.black),
          
          // Fond de caméra avec aspect ratio correct
          _buildCameraBackground(),
          
          // Interface utilisateur superposée
          SafeArea(
            child: Column(
              children: [
                // Barre supérieure avec bouton de retour
                _buildAppBar(),
                
                // Affichage des capteurs
                _buildSensorOverlay(),
                
                const Spacer(),
                
                // Liste des mesures
                _buildMeasurementsList(),
                
                // Boutons d'action
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCameraBackground() {
    if (!_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    // Utiliser une approche beaucoup plus directe avec moins de transformations
    return Container(
      color: Colors.black,
      child: Align(
        alignment: Alignment.center,
        child: Stack(
          children: [
            // La caméra sans transformations supplémentaires
            CameraPreview(_cameraController!),
            
            // Ajouter un indicateur pour le centre
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
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
            Colors.black.withOpacity(0.7),
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
          
          GestureDetector(
            onTap: _addMeasurement,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_location_alt,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          
          _buildSensorDisplay(
            "ÉLÉVATION",
            "${_elevation.toStringAsFixed(1)}°",
            Colors.orange,
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
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.7),
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
          color: Colors.black.withOpacity(0.6),
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
        color: Colors.black.withOpacity(0.6),
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
                    color: Colors.white.withOpacity(0.2),
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
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            'CSV',
            Icons.file_download,
            Colors.blueGrey.shade700,
            _exportToCsv,
          ),
          
          _buildActionButton(
            'Terminer',
            Icons.check,
            Colors.green.shade700,
            _finishAndReturn,
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
}
