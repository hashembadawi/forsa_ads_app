import 'category.dart';
import 'sub_category.dart';
import 'currency_option.dart';
import 'province.dart';
import 'major_area.dart';

class AppOptions {
  final List<Category> categories;
  final List<SubCategory> subCategories;
  final List<CurrencyOption> currencies;
  final List<Province> provinces;
  final List<MajorArea> majorAreas;

  AppOptions({
    required this.categories,
    required this.subCategories,
    required this.currencies,
    required this.provinces,
    required this.majorAreas,
  });

  factory AppOptions.fromJson(Map<String, dynamic> json) {
    // Support alternative keys and possible wrappers
    List<dynamic>? _arrayOf(Map<String, dynamic> src, List<String> keys) {
      for (final k in keys) {
  final v = src[k];
  if (v is List) return v;
      }
      return const [];
    }

  final categoriesJson = _arrayOf(json, ['categories', 'Categories']) ?? const [];
  final subCategoriesJson = _arrayOf(json, ['subCategories', 'SubCategories', 'subcategories', 'sub_categories']) ?? const [];
  final currenciesJson = _arrayOf(json, ['currencies', 'Currencies']) ?? const [];
  final provincesJson = _arrayOf(json, ['Province', 'provinces', 'Provinces']) ?? const [];
  final majorAreasJson = _arrayOf(json, ['majorAreas', 'MajorAreas']) ?? const [];

    return AppOptions(
      categories: categoriesJson
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList(),
      subCategories: subCategoriesJson
        .map((e) => SubCategory.fromJson(e as Map<String, dynamic>))
        .toList(),
      currencies: currenciesJson
        .map((e) => CurrencyOption.fromJson(e as Map<String, dynamic>))
        .toList(),
      provinces: provincesJson
        .map((e) => Province.fromJson(e as Map<String, dynamic>))
        .toList(),
      majorAreas: majorAreasJson
        .map((e) => MajorArea.fromJson(e as Map<String, dynamic>))
        .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((e) => e.toJson()).toList(),
      'subCategories': subCategories.map((e) => e.toJson()).toList(),
      'currencies': currencies.map((e) => e.toJson()).toList(),
      'Province': provinces.map((e) => e.toJson()).toList(),
      'majorAreas': majorAreas.map((e) => e.toJson()).toList(),
    };
  }
}
