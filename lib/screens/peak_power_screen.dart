import 'package:flutter/material.dart';

class PeakPowerScreen extends StatefulWidget {
  const PeakPowerScreen({super.key});

  @override
  State<PeakPowerScreen> createState() => _PeakPowerScreenState();
}

class _PeakPowerScreenState extends State<PeakPowerScreen> {
  final TextEditingController _powerController = TextEditingController(text: '1.0');
  final FocusNode _powerFocusNode = FocusNode();
  double _peakPower = 1.0; // Valeur par défaut

  @override
  void initState() {
    super.initState();
    // Donner le focus au champ dès le chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _powerFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _powerController.dispose();
    _powerFocusNode.dispose();
    super.dispose();
  }

  void _updatePower(String value) {
    try {
      final newPower = double.parse(value.replaceAll(',', '.'));
      if (newPower > 0) {
        setState(() => _peakPower = newPower);
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }
  }

  void _confirmAndNavigateBack() {
    Navigator.pop(context, _peakPower);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puissance PV crête'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quelle est la puissance PV crête installée ?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            Text(
              'Puissance PV crête installée [kWp]',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _powerController,
              focusNode: _powerFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffix: const Text('kWp'),
                hintText: '3.0',
              ),
              onChanged: _updatePower,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'La puissance crête correspond à la puissance maximale que peut produire votre installation dans des conditions optimales.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmAndNavigateBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
