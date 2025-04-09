import 'package:flutter/foundation.dart';
import '../models/roof_pan.dart';

class RoofPansProvider with ChangeNotifier {
  final List<RoofPan> _pans = [];

  List<RoofPan> get pans => List.unmodifiable(_pans);

  void addPan(RoofPan pan) {
    _pans.add(pan);
    notifyListeners();
  }

  void removePan(String id) {
    _pans.removeWhere((pan) => pan.id == id);
    notifyListeners();
  }

  void clear() {
    _pans.clear();
    notifyListeners();
  }
}
