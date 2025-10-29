import 'package:flutter/material.dart';

class Step1CategoryOptions extends StatelessWidget {
  final Map<String, dynamic> adData;
  final Function(String key, dynamic value) onDataChanged;

  const Step1CategoryOptions({
    super.key,
    required this.adData,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Selection
        DropdownButtonFormField<int>(
          value: adData['categoryId'],
          decoration: const InputDecoration(
            labelText: 'التصنيف الرئيسي',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            filled: false,
          ),
          items: const [
            // TODO: Load from API
            DropdownMenuItem(value: 1, child: Text('إلكترونيات')),
            DropdownMenuItem(value: 2, child: Text('سيارات')),
            DropdownMenuItem(value: 3, child: Text('عقارات')),
          ],
          onChanged: (value) {
            onDataChanged('categoryId', value);
            onDataChanged('categoryName', 'إلكترونيات'); // TODO: Get actual name
          },
        ),
        const SizedBox(height: 12),

        // SubCategory Selection
        DropdownButtonFormField<int>(
          value: adData['subCategoryId'],
          decoration: const InputDecoration(
            labelText: 'التصنيف الفرعي',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            filled: false,
          ),
          items: const [
            // TODO: Load based on category
            DropdownMenuItem(value: 1, child: Text('هواتف')),
            DropdownMenuItem(value: 2, child: Text('أجهزة كمبيوتر')),
          ],
          onChanged: (value) {
            onDataChanged('subCategoryId', value);
            onDataChanged('subCategoryName', 'هواتف'); // TODO: Get actual name
          },
        ),
        const SizedBox(height: 16),

        // For Sale Switch
        SwitchListTile(
          title: const Text('للبيع'),
          subtitle: const Text('إذا كان الإعلان للإيجار، قم بإلغاء التحديد'),
          value: adData['forSale'] ?? true,
          onChanged: (value) => onDataChanged('forSale', value),
          contentPadding: EdgeInsets.zero,
        ),

        // Delivery Service Switch
        SwitchListTile(
          title: const Text('خدمة التوصيل'),
          subtitle: const Text('هل تقدم خدمة توصيل للمنتج؟'),
          value: adData['deliveryService'] ?? false,
          onChanged: (value) => onDataChanged('deliveryService', value),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
