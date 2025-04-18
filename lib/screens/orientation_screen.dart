import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  double _orientation = 180.0; // Sud par défaut (180°)
  bool _autoMeasure = true;
  final TextEditingController _manualOrientationController = TextEditingController();
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasCompass = false;

  @override
  void initState() {
    super.initState();
    _manualOrientationController.text = _orientation.round().toString();
    _checkCompassAvailability();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _manualOrientationController.dispose();
    super.dispose();
  }

  void _checkCompassAvailability() async {
    // Vérifier si la boussole est disponible
    bool? hasCompass = await FlutterCompass.events?.isEmpty;
    
    setState(() {
      _hasCompass = hasCompass == false;
      
      if (_hasCompass) {
        _startListening();
      } else {
        _autoMeasure = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Boussole non disponible. Utilisez le mode manuel.'),
          ),
        );
      }
    });
  }

  void _startListening() {
    if (!_hasCompass) return;
    
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      // Correction de l'orientation pour éviter les valeurs négatives
      if (event.heading != null && _autoMeasure && mounted) {
        setState(() {
          // Normaliser l'angle pour qu'il soit toujours entre 0 et 360 degrés
          double heading = event.heading!;
          if (heading < 0) {
            heading = 360 + heading;
          }
          _orientation = heading;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orientation du pan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quelle est l\'orientation du pan ?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Switch pour choisir entre mesure auto et manuelle
            Row(
              children: [
                Checkbox(
                  value: _autoMeasure && _hasCompass,
                  onChanged: _hasCompass ? (value) {
                    setState(() {
                      _autoMeasure = value ?? true;
                      if (!_autoMeasure) {
                        _manualOrientationController.text = _orientation.round().toString();
                      }
                    });
                  } : null,
                ),
                // Utiliser l'interpolation de chaîne au lieu de la concaténation
                Text('Mesurer automatiquement${!_hasCompass ? ' (non disponible)' : ''}'),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Contenu conditionnel selon le mode
            _autoMeasure && _hasCompass ? _buildAutoMeasureUI() : _buildManualEntryUI(),
            
            const Spacer(),
            
            // Bouton de validation
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final selectedOrientation = _autoMeasure && _hasCompass
                      ? _orientation
                      : double.tryParse(_manualOrientationController.text) ?? 0.0;
                  
                  double normalizedOrientation = selectedOrientation % 360;
                  if (normalizedOrientation < 0) normalizedOrientation += 360;
                  
                  Navigator.pop(context, normalizedOrientation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Valider l\'orientation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAutoMeasureUI() {
    return Column(
      children: [
        // Boussole améliorée
        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Titre avec icône
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, 
                        color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Orientation mesurée',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Valeur d'orientation avec animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _orientation),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        '${value.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // PARTIE COMPLÈTEMENT RECONSTRUITE - Boussole avec rotation correcte
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle externe décoratif
                        Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.grey.shade100,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.shade300, 
                              width: 2.5
                            ),
                          ),
                        ),
                        
                        // Animation fluide du cadran
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0, 
                            end: (-(_orientation % 360) * pi / 180)
                          ),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, __) {
                            return Transform.rotate(
                              angle: value,
                              child: CustomPaint(
                                size: const Size(190, 190),
                                painter: _CompassDialPainter(context),
                              ),
                            );
                          },
                        ),
                        
                        // Aiguille de boussole fixe améliorée
                        SizedBox(
                          height: 120,
                          width: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Point central de l'aiguille
                              Container(
                                height: 20,
                                width: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(51),
                                      blurRadius: 4,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Flèche Nord avec CustomPaint pour plus de beauté
                              CustomPaint(
                                size: const Size(8, 100),
                                painter: _CompassNeedlePainter(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Texte d'aide amélioré
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                const Color.fromRGBO(230, 240, 255, 1)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.shade100,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline, 
                color: Colors.blue.shade700,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tenez votre téléphone à plat. L\'aiguille indique toujours le nord magnétique. Lisez l\'orientation du pan sur le cadran.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntryUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saisissez l\'orientation en degrés:',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _manualOrientationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            labelText: 'Orientation (degrés)',
            hintText: '180° = Sud, 90° = Est, 270° = Ouest',
            suffixText: '°',
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Remplacer withOpacity par une couleur avec valeur alpha directe
            color: const Color.fromRGBO(255, 152, 0, 0.1), // Orange avec opacité 0.1
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Points cardinaux:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Sud = 180°, Est = 90°'),
              const Text('Ouest = 270°, Nord = 0° ou 360°'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Ou ajustez avec le curseur:'),
        Slider(
          value: double.tryParse(_manualOrientationController.text) ?? 180.0,
          min: 0,
          max: 360,
          divisions: 72, // Tous les 5 degrés
          label: '${double.tryParse(_manualOrientationController.text)?.round() ?? 180}°',
          onChanged: (value) {
            setState(() {
              _manualOrientationController.text = value.round().toString();
            });
          },
        ),
      ],
    );
  }
}

// Painter personnalisé pour l'aiguille de boussole
class _CompassNeedlePainter extends CustomPainter {
  final Color color;
  
  _CompassNeedlePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
      
    // Crée un effet de brillance avec un dégradé
    final paintGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withAlpha(178)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height / 5))
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Moitié Nord (pointe) - forme plus sophistiquée
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height / 5);
    path.lineTo(size.width, size.height / 5);
    path.close();
    
    canvas.drawPath(path, paintGradient);
    
    // Corps de l'aiguille avec dégradé
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          color.withAlpha(178),
        ],
      ).createShader(Rect.fromLTWH(
        size.width / 2 - 1.5, 
        size.height / 5, 
        3, 
        size.height * 0.75
      ))
      ..style = PaintingStyle.fill;
        
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2 - 1.5, 
        size.height / 5, 
        3, 
        size.height * 0.75
      ), 
      bodyPaint
    );
    
    // Ajout d'un effet d'ombre subtil
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
    canvas.drawPath(path.shift(const Offset(1, 1)), shadowPaint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Nouveau peintre pour le cadran de la boussole sans barres
class _CompassDialPainter extends CustomPainter {
  final BuildContext context;
  
  _CompassDialPainter(this.context);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Peinture pour les graduations
    final tickPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Dessiner cercle intérieur décoratif
    final circlePaint = Paint()
      ..color = Colors.white.withAlpha(178)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.6, circlePaint);
    
    // Ajouter bordure au cercle intérieur
    final circleBorderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawCircle(center, radius * 0.6, circleBorderPaint);
    
    // Dessiner les graduations
    for (int i = 0; i < 36; i++) {
      final angle = (i * pi / 18);
      final tickLength = i % 9 == 0 ? 12.0 : (i % 3 == 0 ? 8.0 : 4.0);
      final tickWidth = i % 9 == 0 ? 2.0 : 1.0;
      
      final p1 = center + Offset(
        radius * sin(angle), 
        -radius * cos(angle)
      );
      
      // Dessiner les graduations comme de simples lignes
      final tickPaint = Paint()
        ..color = i % 9 == 0 ? Colors.black87 : Colors.grey.shade500
        ..strokeWidth = tickWidth;
        
      canvas.save();
      canvas.translate(p1.dx, p1.dy);
      canvas.rotate(angle);
      canvas.drawLine(
        Offset.zero, 
        Offset(0, -tickLength), 
        tickPaint
      );
      canvas.restore();
    }
    
    // Dessiner le texte des points cardinaux - SANS AUCUNE DÉCORATION
    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    // Points cardinaux principaux (N, E, S, O)
    final List<String> mainPoints = ['N', 'E', 'S', 'O'];
    final List<Offset> mainPositions = [
      Offset(center.dx, center.dy - radius * 0.88),  // N
      Offset(center.dx + radius * 0.88, center.dy),  // E
      Offset(center.dx, center.dy + radius * 0.88),  // S
      Offset(center.dx - radius * 0.88, center.dy),  // O
    ];
    
    for (int i = 0; i < mainPoints.length; i++) {
      textPainter.text = TextSpan(
        text: mainPoints[i],
        style: TextStyle(
          color: i == 0 ? Colors.red.shade700 : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        mainPositions[i] - Offset(textPainter.width / 2, textPainter.height / 2)
      );
    }
    
    // Points cardinaux secondaires (NE, SE, SO, NO)
    final List<String> secondaryPoints = ['NE', 'SE', 'SO', 'NO'];
    final List<Offset> secondaryPositions = [
      Offset(center.dx + radius * 0.62, center.dy - radius * 0.62),  // NE
      Offset(center.dx + radius * 0.62, center.dy + radius * 0.62),  // SE
      Offset(center.dx - radius * 0.62, center.dy + radius * 0.62),  // SO
      Offset(center.dx - radius * 0.62, center.dy - radius * 0.62),  // NO
    ];
    
    for (int i = 0; i < secondaryPoints.length; i++) {
      textPainter.text = TextSpan(
        text: secondaryPoints[i],
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        secondaryPositions[i] - Offset(textPainter.width / 2, textPainter.height / 2)
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
