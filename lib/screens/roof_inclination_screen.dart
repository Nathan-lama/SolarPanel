import 'package:flutter/material.dart';
import 'obstacles_pan_screen.dart';

class RoofInclinationScreen extends StatefulWidget {
  final Map<String, dynamic> panData;
  
  const RoofInclinationScreen({super.key, required this.panData});
  
  @override
  State<RoofInclinationScreen> createState() => _RoofInclinationScreenState();
}

class _RoofInclinationScreenState extends State<RoofInclinationScreen> {
  double _selectedInclination = 0.0;
  
  void _continueToNextScreen() {
    // Obtenir l'orientation du panData existant
    final double orientation = widget.panData['orientation'] ?? 0.0;
    
    // Obtenir la puissance PV du panData existant ou utiliser une valeur par défaut de 3.0
    final double peakPower = widget.panData['peakPower'] ?? 3.0;
    
    // Navigation vers l'écran des obstacles avec orientation, inclinaison et puissance crête
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ObstaclesPanScreen(
          orientation: orientation,
          inclination: _selectedInclination,
          peakPower: peakPower, // Ajouter le paramètre requis
        ),
      ),
    );
  }
  
  // Implémentation de la méthode build() obligatoire
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inclinaison du toit'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choisissez l\'inclinaison de votre toit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Affichage de l'inclinaison actuelle
            Text(
              '${_selectedInclination.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Slider pour sélectionner l'inclinaison
            Slider(
              value: _selectedInclination,
              min: 0,
              max: 45, // Inclinaison maximale typique pour un toit
              divisions: 45,
              label: _selectedInclination.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _selectedInclination = value;
                });
              },
            ),
            const SizedBox(height: 20),
            // Illustrations visuelles des différentes inclinaisons
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInclinationExample(0, '0°', _selectedInclination < 15),
                  _buildInclinationExample(22.5, '22.5°', _selectedInclination >= 15 && _selectedInclination < 30),
                  _buildInclinationExample(45, '45°', _selectedInclination >= 30),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Bouton pour continuer
            ElevatedButton(
              onPressed: _continueToNextScreen,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget pour afficher une illustration d'inclinaison
  Widget _buildInclinationExample(double angle, String label, bool isSelected) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Transform.rotate(
            angle: angle * 3.14159 / 180,
            child: Container(
              width: 80,
              height: 5,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}