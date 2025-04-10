import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/roof_pan.dart'; // Pour accéder à la classe RoofPan

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
  late CameraController _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  String? _videoPath;
  bool _isCameraInitialized = false;
  bool _hasObstacles = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: true,
        );
        await _cameraController.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'initialisation de la caméra: $e')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final XFile video = await _cameraController.stopVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _videoPath = video.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vidéo enregistrée')),
      );
    } else {
      await _cameraController.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
      });
    }
  }

  @override
  void dispose() {
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  void _finishAndReturnToPansList() {
    // Créer le pan de toit avec toutes les informations collectées
    final newPan = RoofPan(
      orientation: widget.orientation,
      inclination: widget.inclination,
      hasObstacles: _hasObstacles,
      obstaclesVideoPath: _videoPath,
    );
    
    // Retourner à la liste des pans avec le nouveau pan créé
    Navigator.pop(context, newPan);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détection d\'obstacles'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: _hasObstacles 
                ? CameraPreview(_cameraController)
                : const Center(child: Text('Pas d\'obstacles à filmer')),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Y a-t-il des obstacles qui pourraient affecter les panneaux solaires ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Présence d\'obstacles:'),
                    Switch(
                      value: _hasObstacles,
                      onChanged: (value) {
                        setState(() {
                          _hasObstacles = value;
                          if (!_hasObstacles) {
                            // Si on désactive les obstacles, on annule la vidéo
                            _videoPath = null;
                            if (_isRecording) {
                              _cameraController.stopVideoRecording();
                              _isRecording = false;
                            }
                          }
                        });
                      },
                    ),
                    Text(_hasObstacles ? 'Oui' : 'Non'),
                  ],
                ),
                const SizedBox(height: 16),
                if (_hasObstacles)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _toggleRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording ? Colors.red : Colors.blue,
                        ),
                        child: Text(_isRecording ? 'Arrêter' : 'Enregistrer vidéo'),
                      ),
                      if (_videoPath != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (_hasObstacles && _videoPath == null && !_isRecording) 
                      ? null 
                      : _finishAndReturnToPansList,
                  child: const Text('Terminer et ajouter le pan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
