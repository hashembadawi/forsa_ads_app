import 'package:flutter/material.dart';
import '../../../data/models/app_options.dart';
import '../../../data/models/sub_category.dart';

class Step1CategoryOptions extends StatelessWidget {
  final Map<String, dynamic> adData;
  final AppOptions options;
  final Function(String key, dynamic value) onDataChanged;

  const Step1CategoryOptions({
    super.key,
    required this.adData,
    required this.options,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Filter subcategories based on selected category
    final selectedCategoryId = adData['categoryId'];
  final List<SubCategory> filteredSubCategories = selectedCategoryId != null
    ? options.subCategories.where((sub) => sub.categoryId == selectedCategoryId).toList()
    : <SubCategory>[];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Selection
          DropdownButtonFormField<int>(
          value: adData['categoryId'],
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'التصنيف الرئيسي',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          items: options.categories.map((category) {
            return DropdownMenuItem<int>(
              value: category.id,
              child: Text(
                category.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (value) {
            final selectedCategory = options.categories.firstWhere((cat) => cat.id == value);
            onDataChanged('categoryId', value);
            onDataChanged('categoryName', selectedCategory.name);
            // Reset subcategory when category changes
            onDataChanged('subCategoryId', null);
            onDataChanged('subCategoryName', null);
          },
        ),
        const SizedBox(height: 12),

        // SubCategory Selection
        DropdownButtonFormField<int>(
          value: adData['subCategoryId'],
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'التصنيف الفرعي',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            hintText: selectedCategoryId == null ? 'اختر التصنيف الرئيسي أولاً' : 'اختر التصنيف الفرعي',
          ),
          items: filteredSubCategories.map((subCategory) {
            return DropdownMenuItem<int>(
              value: subCategory.id,
              child: Text(
                subCategory.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: selectedCategoryId == null ? null : (value) {
            if (value != null) {
              final selectedSubCategory = filteredSubCategories.firstWhere((sub) => sub.id == value);
              onDataChanged('subCategoryId', value);
              onDataChanged('subCategoryName', selectedSubCategory.name);
            }
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
    ),
    );
  }
}
