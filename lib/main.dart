import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://etaeeuinclewwymorhtx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0YWVldWluY2xld3d5bW9yaHR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ5MTg0MjIsImV4cCI6MjA2MDQ5NDQyMn0.mXNAEdaPMygM3nvlUMbol_azJFv782OVV1amsVBTCLQ',
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
