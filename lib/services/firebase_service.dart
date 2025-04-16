import 'package:cloud_firestore/cloud_firestore.dart';

/// Service pour gérer les opérations avec Firebase
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'roof_data';
  
  /// Sauvegarde les données de toit dans la collection Firestore
  static Future<void> saveRoofData(Map<String, dynamic> data) async {
    try {
      // Ajouter une nouvelle entrée avec un ID automatique
      await _firestore.collection(_collectionName).add(data);
    } catch (e) {
      // Remonter l'erreur pour qu'elle soit gérée par l'appelant
      throw 'Erreur lors de l\'enregistrement des données: ${e.toString()}';
    }
  }
  
  /// Récupère l'historique des données envoyées (pour une fonctionnalité future)
  static Future<List<Map<String, dynamic>>> getRoofDataHistory() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Erreur lors de la récupération des données: ${e.toString()}';
    }
  }
}
