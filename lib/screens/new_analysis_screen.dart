import 'package:flutter/material.dart';
import 'location_screen.dart';

class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  State<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientSurnameController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  bool _isRequiredOnly = true;

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientSurnameController.dispose();
    _clientAddressController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    super.dispose();
  }

  void _continueToLocation() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Passer à l'écran de localisation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationScreen(
          clientName: _clientNameController.text,
          clientSurname: _clientSurnameController.text,
          clientEmail: _clientEmailController.text,
          clientAddress: _clientAddressController.text,
          clientPhone: _clientPhoneController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle analyse'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et description
                Text(
                  'Informations du client',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Commencez par renseigner les informations du client pour cette analyse.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Champs obligatoires
                Text(
                  'Informations obligatoires',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Prénom du client
                TextFormField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le prénom du client';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Nom du client
                TextFormField(
                  controller: _clientSurnameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le nom du client';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                
                // Switch pour afficher les champs optionnels
                SwitchListTile(
                  title: Text(
                    'Ajouter des informations complémentaires',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  value: !_isRequiredOnly,
                  onChanged: (value) {
                    setState(() {
                      _isRequiredOnly = !value;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                
                // Champs optionnels
                if (!_isRequiredOnly) ...[
                  const SizedBox(height: 16),
                  
                  // Email
                  TextFormField(
                    controller: _clientEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Téléphone
                  TextFormField(
                    controller: _clientPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Adresse
                  TextFormField(
                    controller: _clientAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Bouton de continuation
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _continueToLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
