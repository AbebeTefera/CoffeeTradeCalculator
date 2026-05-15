// lib/screens/standard_calculator.dart
import 'package:flutter/material.dart';

class StandardCalculator extends StatefulWidget {
  const StandardCalculator({super.key});

  @override
  State<StandardCalculator> createState() => _StandardCalculatorState();
}

class _StandardCalculatorState extends State<StandardCalculator> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _waitingForOperand = false;

  void _buttonPressed(String text) {
    setState(() {
      if (text == 'C') {
        _display = '0';
        _firstOperand = null;
        _operator = null;
        _waitingForOperand = false;
      } else if (text == '+' || text == '-' || text == '×' || text == '÷') {
        if (_firstOperand == null) {
          _firstOperand = double.tryParse(_display);
        } else if (!_waitingForOperand && _operator != null) {
          _calculate();
          _firstOperand = double.tryParse(_display);
        }
        _operator = text;
        _waitingForOperand = true;
      } else if (text == '=') {
        if (_operator != null && _firstOperand != null) {
          _calculate();
          _operator = null;
          _firstOperand = null;
          _waitingForOperand = false;
        }
      } else {
        // Digit or decimal point
        if (_waitingForOperand) {
          _display = text;
          _waitingForOperand = false;
        } else {
          if (_display == '0' && text != '.') {
            _display = text;
          } else {
            _display += text;
          }
        }
      }
    });
  }

  void _calculate() {
    double secondOperand = double.tryParse(_display) ?? 0;
    double result;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        result = _firstOperand! / secondOperand;
        break;
      default:
        return;
    }
    _display = result.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.all(20),
            child: Text(
              _display,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildButtonRow(['7', '8', '9', '÷']),
              _buildButtonRow(['4', '5', '6', '×']),
              _buildButtonRow(['1', '2', '3', '-']),
              _buildButtonRow(['0', '.', 'C', '+']),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () => _buttonPressed('='),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('=', style: TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((btn) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: () => _buttonPressed(btn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
                child: Text(btn, style: const TextStyle(fontSize: 24)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}