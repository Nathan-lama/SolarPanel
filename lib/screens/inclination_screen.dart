import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _manualAngleController.dispose();
    super.dispose();
  }

  void _startListening() {
    // Utilisation de accelerometerEventStream() au lieu de accelerometerEvents
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_autoMeasure) {
        // Calculer l'angle d'inclinaison
        double x = event.x;
        double y = event.y;
        double z = event.z;
        
        // Angle entre le vecteur gravité et l'axe z
        double angleInRadians = acos(z / sqrt(x * x + y * y + z * z));
        
        // Convertir en degrés (0° = horizontal, 90° = vertical)
        double angleInDegrees = 90 - (angleInRadians * 180 / pi);
        
        // Appliquer un léger filtre pour stabiliser la lecture
        setState(() {
          _currentAngle = double.parse(angleInDegrees.toStringAsFixed(1));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inclinaison du toit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quelle est l\'inclinaison de votre toit ?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Switch pour choisir entre mesure auto et manuelle
            Row(
              children: [
                Checkbox(
                  value: _autoMeasure,
                  onChanged: (value) {
                    setState(() {
                      _autoMeasure = value ?? true;
                    });
                  },
                ),
                const Text('Mesurer automatiquement'),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Contenu conditionnel selon le mode
            _autoMeasure ? _buildAutoMeasureUI() : _buildManualEntryUI(),
            
            const Spacer(),
            
            // Bouton pour valider l'inclinaison
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Récupérer l'angle choisi
                  final selectedAngle = _autoMeasure 
                      ? _currentAngle 
                      : double.tryParse(_manualAngleController.text) ?? 0.0;
                  
                  // Retourner à l'écran précédent avec la valeur
                  Navigator.pop(context, selectedAngle);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Valider le pan', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoMeasureUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Visualisation de l'angle
        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Column(
                children: [
                  const Text(
                    'Angle mesuré:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_currentAngle.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Visualisation graphique de l'inclinaison
                  Container(
                    height: 120,
                    width: 200,
                    padding: const EdgeInsets.all(10),
                    child: CustomPaint(
                      painter: InclinationPainter(angle: _currentAngle),
                      size: const Size(180, 100),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Texte d'aide
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Utiliser une couleur avec valeur alpha directement au lieu de withOpacityec opacity n'est pas disponible
            color: const Color.fromRGBO(33, 150, 243, 0.1), // Couleur bleue avec alpha à 0.1
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Posez votre téléphone sur le toit ou sur une surface inclinée pour mesurer l\'angle.',
                  style: TextStyle(fontSize: 14),
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
          'Saisissez l\'angle d\'inclinaison en degrés:',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _manualAngleController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            labelText: 'Angle (degrés)',
            hintText: 'Ex: 30°',
            suffixText: '°',
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Utiliser une couleur avec valeur alpha directement au lieu de withOpacityec opacity n'est pas disponible
            color: const Color.fromRGBO(255, 152, 0, 0.1), // Couleur orange avec alpha à 0.1
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'L\'angle d\'inclinaison d\'un toit standard est généralement compris entre 15° et 45°.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Peintre personnalisé pour visualiser l'inclinaison
class InclinationPainter extends CustomPainter {
  final double angle;
  
  InclinationPainter({required this.angle});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Dessiner la ligne horizontale (sol)
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      paint,
    );
    
    // Calculer les points pour la ligne inclinée (toit)
    final double radians = (90 - angle) * pi / 180;
    final double length = size.width * 0.7;
    final Offset start = Offset(size.width * 0.15, size.height * 0.8);
    final Offset end = Offset(
      start.dx + cos(radians) * length,
      start.dy - sin(radians) * length,
    );
    
    // Dessiner la ligne inclinée
    final paintRoof = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawLine(start, end, paintRoof);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
