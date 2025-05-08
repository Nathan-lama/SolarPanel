import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Ajouté pour SystemChrome
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolarPanel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: AuthStateWidget(),
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
