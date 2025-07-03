import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Ajouté pour SystemChrome
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/new_analysis_screen.dart'; // Import the actual screen
import 'screens/client_details_screen.dart';
import 'screens/upgrade_screen.dart';
import 'services/role_guard_service.dart'; // Add this import
import 'services/user_service.dart'; // Add this import
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Forcer l'orientation portrait par défaut pour toute l'application
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Charger les variables d'environnement
  await dotenv.load();
  
  // Initialiser Supabase avec les valeurs du fichier .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolarPanel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/new_analysis': (context) => RoleGuard.guardWidget(
          child: const NewAnalysisScreen(), 
          allowedRoles: [UserRole.admin, UserRole.paidUser],
        ),
        '/client_details': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            return RoleGuard.guardWidget(
              child: ClientDetailsScreen(project: arguments),
              allowedRoles: [UserRole.admin, UserRole.paidUser],
            );
          }
          return const Center(child: Text('Invalid arguments'));
        },
        '/upgrade': (context) => const UpgradeScreen(),
      },
    );
  }
}

// Écran de démarrage pour vérifier l'authentification et les rôles
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // Pour afficher le splash screen
    
    try {
      if (AuthService.isAuthenticated()) {
        final role = await UserService.getCurrentUserRole();
        final route = role == UserRole.freeUser ? '/upgrade' : '/home';
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.solar_power,
              size: 100,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 24),
            Text(
              'SolarPanel',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// Widget pour gérer l'état d'authentification
class AuthStateWidget extends StatelessWidget {
  AuthStateWidget({super.key});

  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Vérifier l'état de connexion actuel
        final session = supabase.auth.currentSession;
        
        if (session != null) {
          // Utilisateur connecté
          return const HomeScreen();
        } else {
          // Utilisateur non connecté
          return const AuthScreen();
        }
      },
    );
  }
}
