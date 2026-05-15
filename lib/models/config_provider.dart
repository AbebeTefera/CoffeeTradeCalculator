import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigProvider extends ChangeNotifier {
  // Editable constants (default values)
  late double bagsPerLot;
  late double bagCost;
  late double vatRate;
  late double tradingFeeRate;
  late double whChargePerBag;

  // Fixed constants (not admin‑editable, but used in formulas)
  static const double conversionFactor = 17.0;    // kg per feresula
  static const double weightPerBagLocal = 85.0;   // Local / unwashed export
  static const double weightPerBagWashed = 60.0;  // Washed export

  ConfigProvider() {
    _loadConstants();
  }

  // Load from SharedPreferences or set defaults
  Future<void> _loadConstants() async {
    final prefs = await SharedPreferences.getInstance();
    bagsPerLot = prefs.getDouble('bagsPerLot') ?? 30.0;
    bagCost = prefs.getDouble('bagCost') ?? 153.0;
    vatRate = prefs.getDouble('vatRate') ?? 0.15;
    tradingFeeRate = prefs.getDouble('tradingFeeRate') ?? 0.005;
    whChargePerBag = prefs.getDouble('whChargePerBag') ?? 28.35;
    notifyListeners();
  }

  // Save a single constant
  Future<void> saveConstant(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
    switch (key) {
      case 'bagsPerLot':
        bagsPerLot = value;
        break;
      case 'bagCost':
        bagCost = value;
        break;
      case 'vatRate':
        vatRate = value;
        break;
      case 'tradingFeeRate':
        tradingFeeRate = value;
        break;
      case 'whChargePerBag':
        whChargePerBag = value;
        break;
    }
    notifyListeners();
  }

  // Reset all to factory defaults
  Future<void> resetToDefaults() async {
    await saveConstant('bagsPerLot', 30.0);
    await saveConstant('bagCost', 153.0);
    await saveConstant('vatRate', 0.15);
    await saveConstant('tradingFeeRate', 0.005);
    await saveConstant('whChargePerBag', 28.35);
  }
}