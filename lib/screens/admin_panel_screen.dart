import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final isAdmin = snapshot.data ?? false;
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Accès refusé')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Accès non autorisé',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Vous n\'avez pas les permissions requises'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Panneau d\'administration'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
                Tab(icon: Icon(Icons.analytics), text: 'Projets'),
                Tab(icon: Icon(Icons.settings), text: 'Paramètres'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              _UsersTab(),
              _ProjectsTab(),
              _SettingsTab(),
            ],
          ),
        );
      },
    );
  }
}

// Onglet de gestion des utilisateurs
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('user_metadata')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun utilisateur trouvé'));
        }
        
        final users = snapshot.data!;
        
        return ListView.builder(
          itemCount: users.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final user = users[index];
            final role = user['role'] as String;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: FutureBuilder<User?>(
                  future: _getUserDetails(user['user_id']),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Text('Chargement...');
                    }
                    return Text(userSnapshot.data?.email ?? 'Inconnu');
                  },
                ),
                subtitle: Text('Rôle: $role'),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleUserAction(context, user, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'admin',
                      child: Text('Définir comme admin'),
                    ),
                    const PopupMenuItem(
                      value: 'paid',
                      child: Text('Définir comme utilisateur payant'),
                    ),
                    const PopupMenuItem(
                      value: 'free',
                      child: Text('Définir comme utilisateur gratuit'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Récupérer les détails d'un utilisateur depuis Supabase Auth
  Future<User?> _getUserDetails(String userId) async {
    try {
      final adminResponse = await Supabase.instance.client.auth.admin
          .getUserById(userId);
      return adminResponse.user;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des détails: $e');
      return null;
    }
  }
  
  // Gérer les actions sur un utilisateur (changer son rôle)
  void _handleUserAction(BuildContext context, Map<String, dynamic> user, String action) async {
    try {
      final userId = user['user_id'] as String;
      UserRole newRole;
      
      switch (action) {
        case 'admin':
          newRole = UserRole.admin;
          break;
        case 'paid':
          newRole = UserRole.paidUser;
          break;
        case 'free':
          newRole = UserRole.freeUser;
          break;
        default:
          return;
      }
      
      await UserService.updateUserRole(userId, newRole);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rôle mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Onglet de gestion des projets
class _ProjectsTab extends StatelessWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('solar_projects')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun projet trouvé'));
        }
        
        final projects = snapshot.data!;
        
        return ListView.builder(
          itemCount: projects.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final project = projects[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(project['name'] ?? 'Projet sans nom'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statut: ${project['status'] ?? 'inconnu'}'),
                    if (project['client_name'] != null)
                      Text('Client: ${project['client_name']}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    // Navigation vers les détails du projet
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Onglet de paramètres
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.storage),
              title: Text('Base de données'),
              subtitle: Text('Dernière sauvegarde: Aujourd\'hui'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paramètres de l\'application',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Mode maintenance'),
                    subtitle: const Text('Activer le mode maintenance de l\'application'),
                    value: false,
                    onChanged: (value) {
                      // Implémenter le changement
                    },
                  ),
                  
                  const Divider(),
                  
                  SwitchListTile(
                    title: const Text('Autoriser les inscriptions'),
                    subtitle: const Text('Permettre aux nouveaux utilisateurs de s\'inscrire'),
                    value: true,
                    onChanged: (value) {
                      // Implémenter le changement
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: () {
              // Implémenter la réinitialisation
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Réinitialiser les paramètres'),
                  content: const Text('Êtes-vous sûr de vouloir réinitialiser tous les paramètres ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Réinitialiser les paramètres
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser les paramètres'),
          ),
        ],
      ),
    );
  }
}
