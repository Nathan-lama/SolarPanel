import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';  // Add this import for AuthService

class UpgradeScreen extends StatefulWidget {  // Changed to StatefulWidget
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mise à niveau du compte'),
      ),
      body: FutureBuilder<UserRole>(
        future: UserService.getCurrentUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userRole = snapshot.data ?? UserRole.freeUser;
          final isPaid = userRole == UserRole.paidUser || userRole == UserRole.admin;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'Votre compte Premium' : 'Passez à la version Premium',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Afficher le statut actuel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPaid ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPaid ? Icons.verified : Icons.info_outline,
                        color: isPaid ? Colors.green : Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPaid ? 'Compte Premium Actif' : 'Compte Gratuit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isPaid
                                  ? 'Vous avez accès à toutes les fonctionnalités'
                                  : 'Accès limité aux fonctionnalités',
                              style: TextStyle(
                                color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Tableau de comparaison des fonctionnalités
                _buildFeatureComparisonTable(context),
                
                const SizedBox(height: 32),
                
                // Bouton de mise à niveau ou d'action
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isPaid ? null : () => _showUpgradeDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isPaid ? 'Déjà Premium' : 'Mettre à niveau maintenant',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Note informative
                if (!isPaid)
                  Text(
                    'La mise à niveau est immédiate après confirmation du paiement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Tableau comparatif des fonctionnalités
  Widget _buildFeatureComparisonTable(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparaison des fonctionnalités',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Fonctionnalité')),
                DataColumn(label: Text('Gratuit')),
                DataColumn(label: Text('Premium')),
              ],
              rows: [
                _buildFeatureRow('Visualisation de base', true, true),
                _buildFeatureRow('Création de projets', false, true),
                _buildFeatureRow('Analyse solaire', false, true),
                _buildFeatureRow('Export PDF', false, true),
                _buildFeatureRow('Historique complet', false, true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Ligne de fonctionnalité
  DataRow _buildFeatureRow(String feature, bool isFree, bool isPremium) {
    return DataRow(
      cells: [
        DataCell(Text(feature)),
        DataCell(
          isFree
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.cancel, color: Colors.red),
        ),
        DataCell(
          isPremium
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.cancel, color: Colors.red),
        ),
      ],
    );
  }

  // Boîte de dialogue pour la mise à niveau
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mise à niveau vers Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'En version de démonstration, la mise à niveau est immédiate sans paiement réel.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dans une version de production, ici vous auriez un formulaire de paiement.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Simuler la mise à niveau (dans une app réelle, cela viendrait après le paiement)
              await _simulateUpgrade(context);
            },
            child: const Text('Continuer avec la simulation'),
          ),
        ],
      ),
    );
  }

  // Simuler la mise à niveau (à remplacer par une vraie intégration de paiement)
  Future<void> _simulateUpgrade(BuildContext context) async {
    try {
      debugPrint('[DEBUG] _simulateUpgrade: Début du processus de mise à niveau');
      
      // Afficher un indicateur de chargement
      debugPrint('[DEBUG] _simulateUpgrade: Affichage du dialogue de chargement');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Mise à niveau en cours...'),
            ],
          ),
        ),
      );
      
      // Simuler un délai de traitement
      debugPrint('[DEBUG] _simulateUpgrade: Simulation d\'un délai de 2 secondes');
      await Future.delayed(const Duration(seconds: 2));
      
      // Vérifier l'utilisateur actuel et son rôle
      final user = AuthService.getCurrentUser();
      debugPrint('[DEBUG] _simulateUpgrade: Utilisateur récupéré: ${user?.id}');
      
      if (user != null) {
        debugPrint('[DEBUG] _simulateUpgrade: Métadonnées actuelles: ${user.userMetadata}');
        
        // Obtenir le rôle actuel
        final roleAvant = await UserService.getCurrentUserRole();
        debugPrint('[DEBUG] _simulateUpgrade: Rôle avant mise à jour: $roleAvant');
        
        // Mettre à jour le rôle
        debugPrint('[DEBUG] _simulateUpgrade: Tentative de mise à jour du rôle...');
        await UserService.setUserRole(UserRole.paidUser);
        
        // Vérifier que le rôle a été mis à jour
        final roleApres = await UserService.getCurrentUserRole();
        debugPrint('[DEBUG] _simulateUpgrade: Rôle après mise à jour: $roleApres');
      }
      
      debugPrint('[DEBUG] _simulateUpgrade: Vérification si le contexte est monté');
      // Fermer le dialogue de chargement
      if (context.mounted) {
        debugPrint('[DEBUG] _simulateUpgrade: Contexte monté, fermeture du dialogue');
        Navigator.pop(context);
        
        // Afficher un message de succès
        debugPrint('[DEBUG] _simulateUpgrade: Affichage du message de succès');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte mis à niveau avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Rafraîchir l'écran
        debugPrint('[DEBUG] _simulateUpgrade: Rafraîchissement de l\'écran de mise à niveau');
        // Forcer une reconstruction du widget
        setState(() {});
        
        // Option alternative: recharger complètement l'écran
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UpgradeScreen()),
          );
        }
      } else {
        debugPrint('[ERREUR] _simulateUpgrade: Le contexte n\'est plus monté!');
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      debugPrint('[ERREUR] _simulateUpgrade: $e');
      debugPrint('[ERREUR] _simulateUpgrade: Stack trace: ${StackTrace.current}');
      
      if (context.mounted) {
        debugPrint('[DEBUG] _simulateUpgrade: Fermeture du dialogue après erreur');
        Navigator.pop(context);
        
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à niveau: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        debugPrint('[ERREUR] _simulateUpgrade: Contexte non monté, impossible d\'afficher l\'erreur');
      }
    }
  }
}
