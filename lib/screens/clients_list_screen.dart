import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import 'dart:developer' as developer;

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _projects = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer uniquement les projets de l'utilisateur actuel
      final currentUser = AuthService.getCurrentUser();
      
      if (currentUser == null) {
        setState(() {
          _errorMessage = "Vous devez être connecté pour voir vos analyses";
          _isLoading = false;
        });
        return;
      }
      
      developer.log('[CLIENTS_LIST] Chargement des projets pour: ${currentUser.id}', 
          name: 'ClientsListScreen');
      
      // Obtenir les projets créés uniquement par cet utilisateur
      final projects = await SupabaseService.getUserProjects(currentUser.id);
      
      developer.log('[CLIENTS_LIST] ${projects.length} projets chargés', 
          name: 'ClientsListScreen');
      
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('[CLIENTS_LIST] Erreur de chargement: $e', 
          name: 'ClientsListScreen', error: e);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProjects,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun client pour le moment',
              style: TextStyle(
                fontSize: 18, 
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez votre première analyse en appuyant sur le bouton ci-dessous',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          return _buildProjectCard(project);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
            tooltip: 'Actualiser',
          ),
          // Ajouter un bouton de debug
          if (AuthService.getCurrentUser() != null)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                final user = AuthService.getCurrentUser();
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Debug Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: ${user?.id}'),
                        Text('Email: ${user?.email}'),
                        Text('Projets trouvés: ${_projects.length}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final projectName = project['name'] ?? 'Client sans nom';
    // Suppression de la variable non utilisée fullName
    final clientEmail = project['client_email'] ?? '';
    final clientPhone = project['client_phone'] ?? '';
    
    final projectDate = DateTime.tryParse(project['created_at'] ?? '');
    final formattedDate = projectDate != null
        ? '${projectDate.day.toString().padLeft(2, '0')}/${projectDate.month.toString().padLeft(2, '0')}/${projectDate.year}'
        : 'Date inconnue';
    
    final roofPans = project['roof_pans'] as List<dynamic>? ?? [];
    final numberOfPans = roofPans.length;
    
    // Calculer la puissance totale
    double totalPower = 0;
    for (var pan in roofPans) {
      if (pan is Map<String, dynamic> && pan['peakPower'] != null) {
        totalPower += (pan['peakPower'] as num).toDouble();
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et date
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    projectName.isNotEmpty ? projectName.substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Créé le $formattedDate',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informations sur l'installation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.architecture, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text('$numberOfPans pan${numberOfPans > 1 ? 's' : ''} de toit'),
                      const Spacer(),
                      Icon(Icons.electric_bolt, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text('${totalPower.toStringAsFixed(1)} kWp'),
                    ],
                  ),
                  if (clientEmail != null && clientEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text(clientEmail, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  ],
                  if (clientPhone != null && clientPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(clientPhone, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
