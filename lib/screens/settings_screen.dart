import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/config_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context);

    // Helper method now has access to 'context'
    Widget buildConstantCard(String label, double currentValue, Function(double) onSaved, {String suffix = ''}) {
      final controller = TextEditingController(text: currentValue.toString());
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        suffixText: suffix,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final newValue = double.tryParse(controller.text);
                      if (newValue != null && newValue > 0) {
                        onSaved(newValue);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a positive number')),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('System Constants (Admin)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildConstantCard('Bags per Lot', config.bagsPerLot, (v) => config.saveConstant('bagsPerLot', v)),
          buildConstantCard('Bag Cost (ETB)', config.bagCost, (v) => config.saveConstant('bagCost', v)),
          buildConstantCard('VAT Rate (%)', config.vatRate * 100, (v) => config.saveConstant('vatRate', v / 100), suffix: '%'),
          buildConstantCard('Trading Fee Rate (%)', config.tradingFeeRate * 100, (v) => config.saveConstant('tradingFeeRate', v / 100), suffix: '%'),
          buildConstantCard('Warehouse Handling Charge (ETB per bag)', config.whChargePerBag, (v) => config.saveConstant('whChargePerBag', v)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await config.resetToDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Constants reset to factory defaults')),
                );
              }
            },
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }
}