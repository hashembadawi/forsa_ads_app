import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Step2AdDetails extends StatefulWidget {
  final Map<String, dynamic> adData;
  final Function(String key, dynamic value) onDataChanged;

  const Step2AdDetails({
    super.key,
    required this.adData,
    required this.onDataChanged,
  });

  @override
  State<Step2AdDetails> createState() => _Step2AdDetailsState();
}

class _Step2AdDetailsState extends State<Step2AdDetails> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.adData['adTitle']);
    _priceController = TextEditingController(
      text: widget.adData['price']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.adData['description'],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ad Title
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'عنوان الإعلان',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          onChanged: (value) => widget.onDataChanged('adTitle', value),
        ),
        const SizedBox(height: 12),

        // Price and Currency Row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  final price = double.tryParse(value);
                  widget.onDataChanged('price', price);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: widget.adData['currencyId'],
                decoration: const InputDecoration(
                  labelText: 'العملة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: const [
                  // TODO: Load from API
                  DropdownMenuItem(value: 1, child: Text('USD')),
                  DropdownMenuItem(value: 2, child: Text('EUR')),
                  DropdownMenuItem(value: 3, child: Text('TRY')),
                ],
                onChanged: (value) {
                  widget.onDataChanged('currencyId', value);
                  widget.onDataChanged('currencyName', 'USD'); // TODO
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // City Selection
        DropdownButtonFormField<int>(
          value: widget.adData['cityId'],
          decoration: const InputDecoration(
            labelText: 'المحافظة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          items: const [
            // TODO: Load from API
            DropdownMenuItem(value: 1, child: Text('دمشق')),
            DropdownMenuItem(value: 2, child: Text('حلب')),
          ],
          onChanged: (value) {
            widget.onDataChanged('cityId', value);
            widget.onDataChanged('cityName', 'دمشق'); // TODO
          },
        ),
        const SizedBox(height: 12),

        // Region Selection
        DropdownButtonFormField<int>(
          value: widget.adData['regionId'],
          decoration: const InputDecoration(
            labelText: 'المنطقة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          items: const [
            // TODO: Load based on city
            DropdownMenuItem(value: 1, child: Text('المزة')),
            DropdownMenuItem(value: 2, child: Text('أبو رمانة')),
          ],
          onChanged: (value) {
            widget.onDataChanged('regionId', value);
            widget.onDataChanged('regionName', 'المزة'); // TODO
          },
        ),
        const SizedBox(height: 12),

        // Location Selection
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Get current location
                  widget.onDataChanged('location', {
                    'coordinates': [33.5138, 36.2765] // Example coordinates
                  });
                },
                icon: const Icon(Icons.my_location),
                label: const Text('الموقع الحالي'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Open map picker
                },
                icon: const Icon(Icons.map),
                label: const Text('من الخريطة'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'وصف المنتج',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          onChanged: (value) => widget.onDataChanged('description', value),
        ),
      ],
    );
  }
}
