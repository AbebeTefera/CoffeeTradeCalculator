import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/config_provider.dart';

class TradeCalculator extends StatefulWidget {
  const TradeCalculator({super.key});

  @override
  State<TradeCalculator> createState() => _TradeCalculatorState();
}
String _formatCurrency(double value) {
  final formatter = NumberFormat("#,##0.00", "en_US");
  return formatter.format(value);
}
class _TradeCalculatorState extends State<TradeCalculator> {
  final _lotController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();

  // Three coffee types
  String _coffeeType = 'Local'; // 'Local', 'Unwashed', 'Washed'
  String _errorMessage = '';
  Map<String, String> _results = {};

  @override
  void dispose() {
    _lotController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _errorMessage = '';
      _results.clear();

      // Parse inputs
      double? lot = _lotController.text.isEmpty ? null : double.tryParse(_lotController.text);
      double? actualWeight = _weightController.text.isEmpty ? null : double.tryParse(_weightController.text);
      double? unitPrice = _priceController.text.isEmpty ? null : double.tryParse(_priceController.text);

      // Validation
      if ((lot != null && lot <= 0) ||
          (actualWeight != null && actualWeight <= 0) ||
          (unitPrice != null && unitPrice <= 0)) {
        _errorMessage = 'All values must be positive numbers (greater than zero).';
        return;
      }
      if (lot == null && actualWeight == null) {
        _errorMessage = 'Please enter at least Lot OR Actual Weight.';
        return;
      }
      if (unitPrice == null) {
        _errorMessage = 'Please enter Unit Price.';
        return;
      }

      final config = Provider.of<ConfigProvider>(context, listen: false);
      final double bagsPerLot = config.bagsPerLot;          // 30
      final double bagCostConstant = config.bagCost;        // 153
      final double vatRate = config.vatRate;                // 0.15
      final double tradingFeeRate = config.tradingFeeRate;  // 0.005
      final double whCharge = config.whChargePerBag;        // 28.35

      // Determine weight per bag and VAT exemption based on coffee type
      double weightPerBag;
      bool vatExempt;
      switch (_coffeeType) {
        case 'Local':
          weightPerBag = ConfigProvider.weightPerBagLocal; // 85
          vatExempt = false;
          break;
        case 'Unwashed':
          weightPerBag = ConfigProvider.weightPerBagLocal; // 85
          vatExempt = true;
          break;
        case 'Washed':
          weightPerBag = ConfigProvider.weightPerBagWashed; // 60
          vatExempt = true;
          break;
        default:
          weightPerBag = ConfigProvider.weightPerBagLocal;
          vatExempt = false;
      }

      const double conversion = ConfigProvider.conversionFactor; // 17 kg/feresula

      // Derive effective lot and effective actual weight
      double effectiveLot;
      double effectiveActualWeight;

      if (lot != null && lot > 0) {
        effectiveLot = lot;
        if (actualWeight != null && actualWeight > 0) {
          effectiveActualWeight = actualWeight;
        } else {
          effectiveActualWeight = effectiveLot * bagsPerLot * weightPerBag;
        }
      } else {
        // Lot not provided, use actual weight to derive lot
        effectiveActualWeight = actualWeight!;
        effectiveLot = effectiveActualWeight / (bagsPerLot * weightPerBag);
      }

      double numberOfBags = effectiveLot * bagsPerLot;
      double bagCost = numberOfBags * bagCostConstant;

      // Adjusted Trade Value (uses effective actual weight)
      double adjustedTradeValue = (effectiveActualWeight / conversion) * unitPrice + bagCost;

      // VAT Charged – only for Local (non‑exempt)
      double vatCharged = vatExempt ? 0.0 : adjustedTradeValue * vatRate;

      // Trade Value (Standardized, uses effective lot)
      double totalWeightKg = numberOfBags * weightPerBag;
      double totalFeresula = totalWeightKg / conversion;
      double tradeValue = (totalFeresula * unitPrice) + bagCost;

      // Trading Fee
      double tradingFee = tradeValue * tradingFeeRate;

      // Warehouse Handling
      double whHandling = numberOfBags * whCharge;

      // ECX VAT (on service charges) – applies to all
      double ecxVat = (tradingFee + whHandling) * vatRate;

      // Final Total
      double finalTotal = adjustedTradeValue + vatCharged + tradingFee + whHandling + ecxVat;

      final format = (double v) => v.toStringAsFixed(2);

      _results = {
        'Coffee Type': _coffeeType,
        'Weight per Bag (kg)': weightPerBag.toString(),
        'VAT Exempt?': vatExempt ? 'Yes' : 'No',
        'Effective Lot (lots)': effectiveLot.toStringAsFixed(2),
        'Number of Bags': numberOfBags.toStringAsFixed(0),
        'Bag Cost (ETB)': _formatCurrency(bagCost),
        'Effective Actual Weight (kg)': effectiveActualWeight.toStringAsFixed(2),
        'Adjusted Trade Value (ETB)': _formatCurrency(adjustedTradeValue),
        'VAT Charged (15%)': vatExempt ? '0.00 (exempt)' : _formatCurrency(vatCharged),
        'Trade Value (Standardized)': _formatCurrency(tradeValue),
        'Trading Fee (0.5%)': _formatCurrency(tradingFee),
        'Warehouse Handling (ETB)': _formatCurrency(whHandling),
        'ECX VAT (15% on fees)': _formatCurrency(ecxVat),
        '═════════════════════': '',
        'FINAL TRADE VALUE (ETB)': _formatCurrency(finalTotal),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COFFEE PRICE CALCULATOR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Coffee Type toggle – three options
          const Text('Coffee Type:'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Local', label: Text('Local (85 kg/bag, VAT applied)')),
              ButtonSegment(value: 'Unwashed', label: Text('Unwashed Export (85 kg/bag, VAT exempt)')),
              ButtonSegment(value: 'Washed', label: Text('Washed Export (60 kg/bag, VAT exempt)')),
            ],
            selected: {_coffeeType},
            onSelectionChanged: (set) {
              setState(() {
                _coffeeType = set.first;
                _calculate();
              });
            },
          ),
          const SizedBox(height: 16),

          // Input fields
          TextField(
            controller: _lotController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Lot (number of lots)',
              border: OutlineInputBorder(),
              hintText: 'e.g., 5',
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Actual Weight (kg) – optional ',
              border: OutlineInputBorder(),
              hintText: 'e.g., 2550',
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Unit Price (ETB per Feresula)',
              border: OutlineInputBorder(),
              hintText: 'e.g., 1250',
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 20),

          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            ),

          if (_results.isNotEmpty)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _results.entries.map((entry) {
                    if (entry.key == '═════════════════════') {
                      return const Divider(thickness: 2);
                    }
                    bool isFinal = entry.key == 'FINAL TRADE VALUE (ETB)';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style: TextStyle(
                                  fontWeight:
                                      isFinal ? FontWeight.bold : FontWeight.normal)),
                          Text(entry.value,
                              style: TextStyle(
                                fontSize: isFinal ? 18 : 14,
                                fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
                                color: isFinal ? Colors.green.shade700 : Colors.black,
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}