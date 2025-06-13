import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class InclinationScreen extends StatefulWidget {
  const InclinationScreen({super.key});

  @override
  State<InclinationScreen> createState() => _InclinationScreenState();
}

class _InclinationScreenState extends State<InclinationScreen> {
  bool _autoMeasure = true;
  double _currentAngle = 0.0;
  final TextEditingController _manualAngleController = TextEditingController();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isPhoneOnEdge = false;
  double _calibrationOffset = 0.0;
  
  // Filtrage des mesures pour plus de stabilité
  final List<double> _angleBuffer = [];
  static const int _bufferSize = 10;

  @override
  void initState() {
    super.initState();
    _manualAngleController.text = "0.0";
    
    // Forcer l'orientation paysage
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _startListening();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _manualAngleController.dispose();
    
    // Cette ligne peut rester, mais elle sera déjà appliquée avant la navigation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    super.dispose();
  }

  void _startListening() {
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!_autoMeasure || !mounted) return;
      
      // En mode paysage, perpendiculaire à la surface:
      // X: gauche-droite quand perpendiculaire (avant-arrière en standard)
      // Y: haut-bas (toujours)
      // Z: avant-arrière devrait être minimal car perpendiculaire à la surface
      
      // Calculer la magnitude totale pour la normalisation
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Ratio de l'axe Z (avant-arrière) sur la magnitude totale
      // Z doit être minimal car le téléphone est perpendiculaire à la surface
      double zRatio = event.z.abs() / magnitude;
      
      // Considérer le téléphone perpendiculaire à la surface quand l'axe Z est minimal
      bool isPerpendicularToSurface = zRatio < 0.3;
      
      if (isPerpendicularToSurface) {
        // Calculer l'angle uniquement à partir des axes X et Y
        // L'axe Y est toujours la composante verticale
        // L'axe X devient horizontal quand le téléphone est perpendiculaire
        double angleInRadians = atan2(event.y, event.x);
        double angleInDegrees = angleInRadians * 180 / pi;
        
        // Appliquer l'offset de calibration
        angleInDegrees -= _calibrationOffset;
        
        // Ajouter au buffer pour stabiliser la mesure
        _angleBuffer.add(angleInDegrees);
        if (_angleBuffer.length > _bufferSize) {
          _angleBuffer.removeAt(0);
        }
        
        // Calculer la moyenne pour un affichage stable
        double smoothedAngle = 0.0;
        if (_angleBuffer.isNotEmpty) {
          smoothedAngle = _angleBuffer.reduce((a, b) => a + b) / _angleBuffer.length;
        }
        
        setState(() {
          _isPhoneOnEdge = true;
          _currentAngle = double.parse(smoothedAngle.toStringAsFixed(1));
          if (_autoMeasure) {
            _manualAngleController.text = _currentAngle.abs().toStringAsFixed(1);
          }
        });
      } else {
        setState(() {
          _isPhoneOnEdge = false;
        });
      }
    });
  }
  
  void _calibrate() {
    if (_isPhoneOnEdge) {
      // Mémoriser l'angle actuel pour l'utiliser comme offset
      setState(() {
        _calibrationOffset = _currentAngle + _calibrationOffset;
        _angleBuffer.clear();
        _currentAngle = 0.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibration effectuée'))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de calibrer. Posez le téléphone sur sa tranche'),
          backgroundColor: Colors.orange,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inclinaison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Calibrer à 0°',
            onPressed: _calibrate,
          ),
        ],
      ),
      // Utiliser un layout qui garantit que tous les éléments sont visibles
      body: SafeArea(
        child: Column(
          children: [
            // Contenu principal qui prend l'espace disponible
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                child: Column(
                  children: [
                    // Titre et switch en ligne pour économiser de l'espace
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Inclinaison du pan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Checkbox(
                          visualDensity: VisualDensity.compact,
                          value: _autoMeasure,
                          onChanged: (value) {
                            setState(() {
                              _autoMeasure = value ?? true;
                              if (!_autoMeasure) {
                                _manualAngleController.text = _currentAngle.abs().toStringAsFixed(1);
                              }
                            });
                          },
                        ),
                        const Text('Auto', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    
                    // Indicateur d'état compact sur la même ligne
                    if (_autoMeasure)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isPhoneOnEdge ? Colors.green.shade50 : Colors.orange.shade50,
                          border: Border.all(
                            color: _isPhoneOnEdge ? Colors.green.shade300 : Colors.orange.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isPhoneOnEdge ? Icons.check_circle : Icons.info_outline,
                              color: _isPhoneOnEdge ? Colors.green : Colors.orange,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isPhoneOnEdge
                                  ? 'Position correcte'
                                  : 'Posez sur la tranche',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isPhoneOnEdge ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Contenu principal selon le mode (prend l'espace restant)
                    Expanded(
                      child: _autoMeasure ? _buildAutoMeasureUI() : _buildManualEntryUI(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bouton de validation (toujours visible en bas et non scrollable)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
              child: ElevatedButton(
                onPressed: () {
                  // Calculer l'angle sélectionné avant tout
                  final selectedAngle = _autoMeasure 
                    ? _currentAngle.abs()
                    : double.tryParse(_manualAngleController.text)?.abs() ?? 0.0;
                  
                  // Basculer en mode portrait
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown,
                  ]);
                  
                  // Retour immédiat sans délai asynchrone
                  Navigator.pop(context, selectedAngle);
                  
                  // Note: Nous avons retiré le Future.delayed car il causait
                  // l'avertissement use_build_context_synchronously
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(45),
                ),
                child: const Text('Valider', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoMeasureUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Angle numérique
          Text(
            _isPhoneOnEdge ? '${_currentAngle.abs().toStringAsFixed(1)}°' : '--°',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('d\'inclinaison', style: TextStyle(fontSize: 14)),
          
          // Illustration améliorée du positionnement
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: pi / 2,
                  child: Icon(
                    Icons.phone_android, 
                    color: _isPhoneOnEdge ? Colors.green : Colors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'perpendiculaire à la surface',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isPhoneOnEdge ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Niveau à bulle (occupant l'espace restant) - MODIFIÉ POUR ÊTRE PLUS GRAND
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 8/1,
                  child: CustomPaint(
                    painter: BubbleLevelPainter(
                      angle: _currentAngle,
                      isActive: _isPhoneOnEdge,
                      primaryColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryUI() {
    // Simplifier l'interface manuelle pour qu'elle soit plus compacte
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Angle d\'inclinaison (degrés):'),
          const SizedBox(height: 8),
          TextField(
            controller: _manualAngleController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixText: '°',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '• Toits standards: entre 15° et 45°',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter pour le niveau à bulle
class BubbleLevelPainter extends CustomPainter {
  final double angle;
  final bool isActive;
  final Color primaryColor;
  
  BubbleLevelPainter({
    required this.angle,
    required this.primaryColor,
    this.isActive = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final levelWidth = size.width - 60; // Augmenté la largeur totale du niveau
    
    // Dessiner le tube du niveau
    final levelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: levelWidth, height: 40),
      const Radius.circular(20),
    );
    
    final levelPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    
    final levelBorderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRRect(levelRect, levelPaint);
    canvas.drawRRect(levelRect, levelBorderPaint);
    
    // Dessiner les graduations
    final centerMarkPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;
    
    // Marque centrale
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      centerMarkPaint,
    );
    
    // Graduations latérales - Modifier pour avoir plus de graduations visibles
    for (int i = 1; i <= 9; i++) { // Augmenté de 6 à 9 graduations de chaque côté
      // Facteur de sensibilité
      double sensitivity = 2.0; // Réduit de 2.5 à 2.0 pour voir plus de graduations
      final offset = i * 10.0 * sensitivity;
      
      if (center.dx + offset <= center.dx + levelWidth / 2 - 10) {
        final markHeight = i % 3 == 0 ? 16.0 : 10.0;
        
        // Graduation droite
        canvas.drawLine(
          Offset(center.dx + offset, center.dy - markHeight / 2),
          Offset(center.dx + offset, center.dy + markHeight / 2),
          centerMarkPaint,
        );
        
        // Texte de graduation
        if (i % 3 == 0) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${i * 10}°',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          );
          textPainter.layout();
          textPainter.paint(
            canvas, 
            Offset(center.dx + offset - textPainter.width / 2, center.dy + 12),
          );
        }
      }
      
      if (center.dx - offset >= center.dx - levelWidth / 2 + 10) {
        final markHeight = i % 3 == 0 ? 16.0 : 10.0;
        
        // Graduation gauche
        canvas.drawLine(
          Offset(center.dx - offset, center.dy - markHeight / 2),
          Offset(center.dx - offset, center.dy + markHeight / 2),
          centerMarkPaint,
        );
        
        // Texte de graduation
        if (i % 3 == 0) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${i * 10}°',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          );
          textPainter.layout();
          textPainter.paint(
            canvas, 
            Offset(center.dx - offset - textPainter.width / 2, center.dy + 12),
          );
        }
      }
    }
    
    if (isActive) {
      // Calculer la position de la bulle
      final double sensitivity = 2.0; // Réduit de 2.5 à 2.0 pour être cohérent
      // Afficher la bulle en fonction de l'angle, mais montrer le degré exact en positif
      final double bubbleOffset = angle * sensitivity; // Garder le signe pour le mouvement visuel
      final double constrainedOffset = bubbleOffset.clamp(-levelWidth / 2 + 20, levelWidth / 2 - 20);
      final bubbleCenter = Offset(center.dx + constrainedOffset, center.dy);
      
      // Dessiner l'ombre de la bulle avec un alpha en constante
      final shadowPaint = Paint()
        ..color = const Color.fromRGBO(0, 0, 0, 0.1) // Utiliser fromRGBO au lieu de withOpacity
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(bubbleCenter, 18, shadowPaint);
      
      // Dessiner la bulle
      final bubblePaint = Paint()
        ..color = primaryColor;
      
      canvas.drawCircle(bubbleCenter, 16, bubblePaint);
      
      // Ajouter un reflet pour l'effet 3D
      final highlightPaint = Paint()
        ..color = const Color.fromRGBO(255, 255, 255, 0.5); // Remplacer withOpacity par fromRGBO
      
      canvas.drawCircle(
        Offset(bubbleCenter.dx - 5, bubbleCenter.dy - 5),
        6,
        highlightPaint,
      );
      
      // Indicateur de précision - basé sur la valeur absolue
      final indicatorColor = angle.abs() < 1 
          ? Colors.green 
          : angle.abs() < 5 
              ? Colors.orange 
              : Colors.red;
      
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 30),
          width: 40,
          height: 4,
        ),
        Paint()..color = indicatorColor,
      );
    } else {
      // Bulle inactive au centre
      final inactivePaint = Paint()
        ..color = Colors.grey.shade400;
      
      canvas.drawCircle(center, 16, inactivePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant BubbleLevelPainter oldDelegate) {
    return oldDelegate.angle != angle || 
           oldDelegate.isActive != isActive || 
           oldDelegate.primaryColor != primaryColor;
  }
}
