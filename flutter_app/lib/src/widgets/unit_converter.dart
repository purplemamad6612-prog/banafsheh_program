import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/product.dart';

class UnitConverter extends StatefulWidget {
  const UnitConverter({
    super.key,
    required this.product,
    this.initialQuantity = 1,
    this.onChanged,
  });

  final Product product;
  final double initialQuantity;
  final void Function(double quantity, ProductUnit unit, double quantityInBase)? onChanged;

  @override
  State<UnitConverter> createState() => _UnitConverterState();
}

class _UnitConverterState extends State<UnitConverter> {
  late final TextEditingController _quantityController;
  late ProductUnit _unit;

  @override
  void initState() {
    super.initState();
    final units = widget.product.sellableUnits;
    _unit = units.isEmpty
        ? ProductUnit(id: '', name: widget.product.baseUnitName, factor: 1)
        : units.first;
    _quantityController = TextEditingController(text: widget.initialQuantity.toString());
    _quantityController.addListener(_emit);
  }

  @override
  void didUpdateWidget(covariant UnitConverter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      final units = widget.product.sellableUnits;
      _unit = units.isEmpty ? ProductUnit(id: '', name: widget.product.baseUnitName, factor: 1) : units.first;
      _quantityController.text = widget.initialQuantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_emit);
    _quantityController.dispose();
    super.dispose();
  }

  void _emit() {
    final quantity = _parseNumber(_quantityController.text);
    widget.onChanged?.call(quantity, _unit, quantity * _unit.factor);
  }

  double _parseNumber(String value) {
    var english = value;
    for (var i = 0; i < 10; i++) {
      english = english.replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i').replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i');
    }
    return double.tryParse(english.replaceAll('٬', '').replaceAll(',', '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final units = widget.product.sellableUnits.isEmpty
        ? [ProductUnit(id: '', name: widget.product.baseUnitName, factor: 1)]
        : widget.product.sellableUnits;
    if (!units.any((unit) => unit.name == _unit.name)) _unit = units.first;
    final quantity = _parseNumber(_quantityController.text);
    final baseQuantity = quantity * _unit.factor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'مقدار', prefixIcon: Icon(Icons.numbers_rounded)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<ProductUnit>(
                value: _unit,
                decoration: const InputDecoration(labelText: 'واحد فروش'),
                items: units
                    .map((unit) => DropdownMenuItem(value: unit, child: Text(unit.name)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _unit = value);
                  _emit();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'معادل ${persianDigits(baseQuantity.toStringAsFixed(3))} ${widget.product.baseUnitName} · ضریب نسخه ${persianDigits(_unit.version)}',
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 10, color: Color(0xFF7B8498)),
        ),
      ],
    );
  }
}
