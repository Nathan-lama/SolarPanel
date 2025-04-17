import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import './services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Supabase
  await SupabaseService.initialize(
    // Remplacer par vos propres clés Supabase
    supabaseUrl: 'https://etaeeuinclewwymorhtx.supabase.co',
    supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0YWVldWluY2xld3d5bW9yaHR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ5MTg0MjIsImV4cCI6MjA2MDQ5NDQyMn0.mXNAEdaPMygM3nvlUMbol_azJFv782OVV1amsVBTCLQ',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolarPanel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
