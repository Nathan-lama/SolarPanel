import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart'; // Ajouter ce package pour la géolocalisation d'adresses
import 'pans_list_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = true;
  Position? _currentPosition;
  String _errorMessage = '';
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Vérifier et demander la permission
      var status = await Permission.location.request();
      
      if (status.isGranted) {
        // Vérifier si le service de localisation est activé
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Les services de localisation sont désactivés.';
          });
          return;
        }

        // Obtenir la position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        
        // Ajouter un marqueur
        _addMarker(LatLng(position.latitude, position.longitude));
        
        // Centrer la carte sur la position
        _animateToPosition(position);
      } else if (status.isDenied) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'La permission de localisation a été refusée.';
        });
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'La permission de localisation est définitivement refusée. Veuillez l\'activer dans les paramètres.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Une erreur est survenue: ${e.toString()}';
      });
    }
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Ma position'),
        ),
      );
    });
  }

  void _animateToPosition(Position position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<void> _geocodeAddress(String address) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Obtenir les coordonnées à partir de l'adresse
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        // Prendre la première correspondance
        Location location = locations.first;
        
        // Créer une Position pour maintenir la compatibilité avec le reste du code
        Position position = Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        
        // Ajouter un marqueur et centrer la carte
        _addMarker(LatLng(position.latitude, position.longitude));
        _animateToPosition(position);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Adresse non trouvée';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de géolocalisation: ${e.toString()}';
      });
    }
  }
  
  void _showAddressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Entrer une adresse'),
          content: TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Adresse complète',
              hintText: 'Ex: 20 Avenue de Ségur, 75007 Paris, France',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_addressController.text.isNotEmpty) {
                  _geocodeAddress(_addressController.text);
                }
              },
              child: const Text('Rechercher'),
            ),
          ],
        );
      },
    );
  }

  void _continueToNextScreen() {
    if (_currentPosition != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PansListScreen(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre localisation'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Où se trouve votre installation solaire ?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _buildBodyContent(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _currentPosition != null
                        ? _continueToNextScreen
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continuer'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _showAddressDialog, // Modification ici pour appeler le dialogue
                  child: const Text('Entrer l\'adresse manuellement'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Récupération de votre position...'),
          ],
        ),
      );
    } else if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    } else if (_currentPosition != null) {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 15,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      );
    } else {
      return const Center(
        child: Text('Impossible de récupérer votre position'),
      );
    }
  }
}

// Placeholder pour OrientationScreen (à implémenter)
class OrientationScreen extends StatelessWidget {
  const OrientationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orientation des panneaux')),
      body: const Center(child: Text('Écran d\'orientation')),
    );
  }
}
