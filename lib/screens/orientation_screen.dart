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
      // event.heading contient l'angle en degrés (0-360)
      if (event.heading != null && _autoMeasure && mounted) {
        setState(() {
          _orientation = event.heading!;
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
                Text('Mesurer automatiquement' + (!_hasCompass ? ' (non disponible)' : '')),
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
        // Boussole simple
        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Orientation mesurée',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  
                  // Valeur d'orientation
                  Text(
                    '${_orientation.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Affichage simplifié de la boussole
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle externe
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        
                        // Points cardinaux
                        ...['N', 'E', 'S', 'O'].asMap().entries.map((entry) {
                          final index = entry.key;
                          final point = entry.value;
                          return Positioned(
                            top: index == 0 ? 5 : (index == 2 ? 135 : 70),
                            left: index == 1 ? 135 : (index == 3 ? 5 : 70),
                            child: Text(
                              point,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        
                        // Flèche de direction
                        Transform.rotate(
                          angle: (_orientation * pi) / 180,
                          child: Container(
                            width: 120,
                            height: 120,
                            alignment: Alignment.topCenter,
                            child: Icon(
                              Icons.arrow_upward,
                              size: 50,
                              color: Theme.of(context).colorScheme.primary,
                            ),
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
        
        // Texte d'aide
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pointez votre téléphone dans la direction du pan pour mesurer l\'orientation.',
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
            color: Colors.orange.withOpacity(0.1),
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
        
        // Slider pour ajustement facile
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
