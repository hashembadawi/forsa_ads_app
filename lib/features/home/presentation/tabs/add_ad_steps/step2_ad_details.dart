import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../data/models/app_options.dart';

class Step2AdDetails extends StatefulWidget {
  final Map<String, dynamic> adData;
  final AppOptions options;
  final Function(String key, dynamic value) onDataChanged;

  const Step2AdDetails({
    super.key,
    required this.adData,
    required this.options,
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
      // Filter major areas based on selected province
      final selectedProvinceId = widget.adData['cityId'];
      final filteredMajorAreas = selectedProvinceId != null
          ? widget.options.majorAreas.where((area) => area.provinceId == selectedProvinceId).toList()
          : <dynamic>[];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
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
                isExpanded: true,
                selectedItemBuilder: (context) {
                  return widget.options.currencies.map((currency) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        currency.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList();
                },
                  items: widget.options.currencies.map((currency) {
                    return DropdownMenuItem<int>(
                      value: currency.id,
                    child: Text(
                      currency.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    );
                  }).toList(),
                onChanged: (value) {
                    final selectedCurrency = widget.options.currencies.firstWhere((curr) => curr.id == value);
                  widget.onDataChanged('currencyId', value);
                    widget.onDataChanged('currencyName', selectedCurrency.name);
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
            items: widget.options.provinces.map((province) {
              return DropdownMenuItem<int>(
                value: province.id,
                child: Text(province.name),
              );
            }).toList(),
          onChanged: (value) {
              final selectedProvince = widget.options.provinces.firstWhere((prov) => prov.id == value);
            widget.onDataChanged('cityId', value);
              widget.onDataChanged('cityName', selectedProvince.name);
              // Reset region when province changes
              widget.onDataChanged('regionId', null);
              widget.onDataChanged('regionName', null);
          },
        ),
        const SizedBox(height: 12),

        // Region Selection
        DropdownButtonFormField<int>(
          value: widget.adData['regionId'],
          decoration: InputDecoration(
            labelText: 'المنطقة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
              hintText: selectedProvinceId == null ? 'اختر المحافظة أولاً' : 'اختر المنطقة',
          ),
            items: filteredMajorAreas.map((area) {
              return DropdownMenuItem<int>(
                value: area.id,
                child: Text(area.name),
              );
            }).toList(),
          onChanged: selectedProvinceId == null ? null : (value) {
              if (value != null) {
                final selectedArea = filteredMajorAreas.firstWhere((area) => area.id == value);
                widget.onDataChanged('regionId', value);
                widget.onDataChanged('regionName', selectedArea.name);
              }
          },
        ),
        const SizedBox(height: 12),

        // Location Selection
        Row(
          children: [
            Expanded(
              child: AppButton.outlined(
                text: 'الموقع الحالي',
                icon: Icons.my_location,
                onPressed: () {
                  // TODO: Get current location
                  widget.onDataChanged('location', {
                    'coordinates': [33.5138, 36.2765] // Example coordinates
                  });
                },
                size: AppButtonSize.large,
                fullWidth: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.outlined(
                text: 'من الخريطة',
                icon: Icons.map,
                onPressed: () {
                  // TODO: Open map picker
                },
                size: AppButtonSize.large,
                fullWidth: true,
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
    ),
    );
  }

}
