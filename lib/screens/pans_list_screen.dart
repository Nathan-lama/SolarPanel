import 'package:flutter/material.dart';
import '../models/roof_pan.dart';
import 'orientation_screen.dart';
import 'results_screen.dart';
import 'inclination_screen.dart';
import 'obstacles_pan_screen.dart'; // Ajout de l'import pour l'écran des obstacles

class PansListScreen extends StatefulWidget {
  const PansListScreen({super.key});

  @override
  State<PansListScreen> createState() => _PansListScreenState();
}

class _PansListScreenState extends State<PansListScreen> {
  // Liste temporaire pour stocker les pans de toit
  final List<RoofPan> _roofPans = [];

  // Méthode pour ajouter un nouveau pan
  Future<void> _addNewPan() async {
    // Navigation vers l'écran d'orientation
    final double? orientation = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (context) => const OrientationScreen(),
      ),
    );

    // Si l'utilisateur a annulé ou le widget n'est plus monté, on sort
    if (orientation == null || !mounted) return;

    // Navigation vers l'écran d'inclinaison
    final double? inclination = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (context) => const InclinationScreen(),
      ),
    );

    // Si l'utilisateur a annulé ou le widget n'est plus monté, on sort
    if (inclination == null || !mounted) return;

    // Navigation vers l'écran des obstacles
    final RoofPan? newPan = await Navigator.push<RoofPan>(
      context,
      MaterialPageRoute(
        builder: (context) => ObstaclesPanScreen(
          orientation: orientation,
          inclination: inclination,
        ),
      ),
    );

    // Si l'utilisateur a annulé ou le widget n'est plus monté, on sort
    if (newPan == null || !mounted) return;

    // Ajout du nouveau pan à la liste
    setState(() {
      _roofPans.add(newPan);
    });
  }

  // Méthode pour supprimer un pan
  void _deletePan(String id) {
    setState(() {
      _roofPans.removeWhere((pan) => pan.id == id);
    });
  }

  // Navigation vers l'écran de résultats
  void _navigateToResults() {
    if (_roofPans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un pan de toit'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(roofPans: _roofPans),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pans de toit'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Configurez les pans de votre toit',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          
          Expanded(
            child: _roofPans.isEmpty
                ? _buildEmptyState()
                : _buildPansList(),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _addNewPan,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un pan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _navigateToResults,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Analyser tous les pans'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour l'état vide (aucun pan)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.roofing,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun pan de toit configuré',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez un pan pour commencer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher la liste des pans
  Widget _buildPansList() {
    return ListView.builder(
      itemCount: _roofPans.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemBuilder: (context, index) {
        final pan = _roofPans[index];
        return Dismissible(
          key: Key(pan.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _deletePan(pan.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pan ${index + 1} supprimé'),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text('${index + 1}'),
              ),
              title: Text('Pan ${index + 1}'),
              subtitle: Text(pan.toString()),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deletePan(pan.id),
              ),
            ),
          ),
        );
      },
    );
  }
}
