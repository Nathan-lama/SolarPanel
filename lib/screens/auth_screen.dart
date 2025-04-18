import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // Ajout de cet import
import '../services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});  // Correction: utilisation de super.key

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_isLogin) {
        // Connexion
        await AuthService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Inscription
        await AuthService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Vérifiez votre email pour confirmer votre inscription"),
              backgroundColor: Colors.green,
            ),
          );
          
          setState(() {
            _isLogin = true;
            _isLoading = false;
          });
          return;
        }
      }
      
      if (mounted) {
        // Navigation vers l'écran principal si connecté
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _translateAuthError(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur s\'est produite: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  String _translateAuthError(String message) {
    switch (message) {
      case 'Invalid login credentials':
        return 'Identifiants incorrects';
      case 'Email not confirmed':
        return 'Email non confirmé';
      case 'User already registered':
        return 'Cet email est déjà utilisé';
      case 'Password should be at least 6 characters':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      default:
        return message;
    }
  }
  
  void _showResetPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    bool isResetting = false;
    String? resetError;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Réinitialiser le mot de passe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Entrez votre adresse email pour recevoir un lien de réinitialisation'),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: resetError,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: isResetting ? null : () async {
                  final email = resetEmailController.text.trim();
                  
                  if (email.isEmpty) {
                    setDialogState(() {
                      resetError = 'Veuillez entrer votre email';
                    });
                    return;
                  }
                  
                  setDialogState(() {
                    isResetting = true;
                    resetError = null;
                  });
                  
                  try {
                    await AuthService.resetPassword(email);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Instructions envoyées par email'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      isResetting = false;
                      resetError = 'Erreur: ${e.toString()}';
                    });
                  }
                },
                child: isResetting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Envoyer'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo et titre
                Icon(
                  Icons.solar_power,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'SolarPanel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Connexion' : 'Inscription',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                
                // Message d'erreur
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Champ email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Champ mot de passe
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (!_isLogin && value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                
                // Mot de passe oublié (uniquement en mode connexion)
                if (_isLogin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showResetPasswordDialog,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Bouton connexion/inscription
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : Text(_isLogin ? 'Se connecter' : 'S\'inscrire'),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Basculer entre connexion et inscription
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                          });
                        },
                  child: Text(
                    _isLogin
                        ? 'Pas encore de compte ? Inscrivez-vous'
                        : 'Déjà un compte ? Connectez-vous',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
