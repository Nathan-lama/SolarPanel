import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/roof_pan.dart';

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
  CameraController? _controller;
  bool _isLoading = true;
  bool _isRecording = false;
  String? _videoPath;
  bool _hasObstacles = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await controller.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de caméra: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_controller == null) return;

    if (_isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoPath = file.path;
      });
    } else {
      await _controller!.prepareForVideoRecording();
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  void _finishAndReturn() {
    Navigator.pop(
      context,
      RoofPan(
        orientation: widget.orientation,
        inclination: widget.inclination,
        hasObstacles: _hasObstacles,
        obstaclesVideoPath: _videoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détection d\'obstacles'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Section principale
                Expanded(
                  child: _buildMainContent(),
                ),
                
                // Section inférieure
                _buildBottomControls(),
              ],
            ),
    );
  }

  Widget _buildMainContent() {
    // Si on a choisi qu'il y a des obstacles et que la caméra est disponible
    if (_hasObstacles && _controller != null) {
      return Stack(
        children: [
          // Prévisualisation de la caméra
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Indicateurs
          if (_videoPath != null)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Vidéo enregistrée',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          
          // Bouton d'enregistrement
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: _isRecording ? Colors.red : Colors.white,
                onPressed: _toggleRecording,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.videocam,
                  color: _isRecording ? Colors.white : Colors.red,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      );
    } 
    
    // Sinon, on affiche un écran d'information
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasObstacles ? Icons.warning_amber : Icons.check_circle,
              size: 80,
              color: _hasObstacles ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              _hasObstacles
                  ? 'La caméra n\'est pas disponible'
                  : 'Pas d\'obstacles détectés',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _hasObstacles
                  ? 'Impossible d\'accéder à la caméra. Vous pouvez continuer sans enregistrer de vidéo.'
                  : 'Vous avez indiqué qu\'il n\'y a pas d\'obstacles autour du pan de toit.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question
          Text(
            'Y a-t-il des obstacles autour de ce pan de toit?',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Options Oui/Non
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  label: 'Non',
                  icon: Icons.clear,
                  isSelected: !_hasObstacles,
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      _hasObstacles = false;
                      _isRecording = false;
                      _videoPath = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOptionButton(
                  label: 'Oui',
                  icon: Icons.warning,
                  isSelected: _hasObstacles,
                  color: Colors.orange,
                  onTap: () {
                    setState(() {
                      _hasObstacles = true;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Bouton de validation
          ElevatedButton(
            onPressed: _canContinue() ? _finishAndReturn : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              _hasObstacles && _videoPath == null
                  ? 'Enregistrez une vidéo d\'abord'
                  : 'Continuer',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade700),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canContinue() {
    if (!_hasObstacles) return true; // Pas d'obstacles, on peut continuer
    return _videoPath != null; // Sinon, on vérifie qu'une vidéo est enregistrée
  }
}
