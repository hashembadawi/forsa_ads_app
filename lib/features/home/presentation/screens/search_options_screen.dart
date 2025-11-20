import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/ui/notifications.dart';

class SearchOptionsScreen extends StatefulWidget {
  const SearchOptionsScreen({Key? key}) : super(key: key);

  @override
  State<SearchOptionsScreen> createState() => _SearchOptionsScreenState();
}

class _SearchOptionsScreenState extends State<SearchOptionsScreen> {
  // UI state for accordions
  bool _nameOpen = true;
  bool _locationOpen = false;
  bool _advancedOpen = false;

  // Example fields (populated later by backend)
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCity;
  String? _selectedRegion;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedCurrency;
  String _saleType = 'sale'; // or 'rent'
  bool _delivery = false;
  final TextEditingController _minPrice = TextEditingController();
  final TextEditingController _maxPrice = TextEditingController();

  // Placeholder lists - will be filled by backend later
  List<String> _cities = [];
  Map<String, List<String>> _regionsByCity = {};
  List<String> _categories = [];
  Map<String, List<String>> _subcats = {};
  List<String> _currencies = [];

  @override
  void initState() {
    super.initState();
    // Fetch options from backend when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptions();
    });
  }

  bool _loadingOptions = false;

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    final notifyCtx = context;
    try {
      Notifications.showLoading(notifyCtx, message: 'جاري التحميل ...');
      final dio = Dio(BaseOptions(receiveTimeout: const Duration(seconds: 20), connectTimeout: const Duration(seconds: 20)));
      final resp = await dio.get('https://sahbo-app-api.onrender.com/api/options/');

      dynamic raw = resp.data;
      try {
        if (raw is String) raw = jsonDecode(raw);
      } catch (_) {}

      if (raw is! Map) throw Exception('استجابة غير متوقعة من الخادم');

      final Map<String, dynamic> data = Map<String, dynamic>.from(raw);

      // currencies
      final List<dynamic> currenciesRaw = (data['currencies'] as List<dynamic>?) ?? [];
      final List<String> currencies = [];
      for (final c in currenciesRaw) {
        try {
          final name = c['name']?.toString() ?? '';
          if (name.isNotEmpty) currencies.add(name);
        } catch (_) {}
      }

      // categories
      final List<dynamic> categoriesRaw = (data['categories'] as List<dynamic>?) ?? [];
      final Map<int, String> catById = {};
      final List<String> categories = [];
      for (final c in categoriesRaw) {
        try {
          final id = c['id'] as int?;
          final name = c['name']?.toString() ?? '';
          if (id != null && name.isNotEmpty) {
            catById[id] = name;
            categories.add(name);
          }
        } catch (_) {}
      }

      // subCategories grouped by category name
      final List<dynamic> subRaw = (data['subCategories'] as List<dynamic>?) ?? [];
      final Map<String, List<String>> subcats = {};
      for (final s in subRaw) {
        try {
          final cid = s['categoryId'] as int?;
          final sname = s['name']?.toString() ?? '';
          if (cid != null && sname.isNotEmpty) {
            final cname = catById[cid];
            if (cname != null) {
              subcats.putIfAbsent(cname, () => []).add(sname);
            }
          }
        } catch (_) {}
      }

      // Province (cities) and majorAreas (regions)
      final List<dynamic> provRaw = (data['Province'] as List<dynamic>?) ?? [];
      final Map<int, String> provById = {};
      final List<String> cities = [];
      for (final p in provRaw) {
        try {
          final id = p['id'] as int?;
          final name = p['name']?.toString() ?? '';
          if (id != null && name.isNotEmpty) {
            provById[id] = name;
            cities.add(name);
          }
        } catch (_) {}
      }

      final List<dynamic> areasRaw = (data['majorAreas'] as List<dynamic>?) ?? [];
      final Map<String, List<String>> regionsByCity = {};
      for (final a in areasRaw) {
        try {
          final pid = a['ProvinceId'] as int?;
          final name = a['name']?.toString() ?? '';
          if (pid != null && name.isNotEmpty) {
            final cityName = provById[pid];
            if (cityName != null) {
              regionsByCity.putIfAbsent(cityName, () => []).add(name);
            }
          }
        } catch (_) {}
      }

      setState(() {
        _currencies = currencies;
        _categories = categories;
        _subcats = subcats;
        _cities = cities;
        _regionsByCity = regionsByCity;
        _loadingOptions = false;
      });
      Notifications.hideLoading(notifyCtx);
    } catch (e) {
      try {
        Notifications.hideLoading(notifyCtx);
      } catch (_) {}
      setState(() => _loadingOptions = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      Notifications.showError(context, msg);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خيارات البحث')),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ExpansionTile(
                    initiallyExpanded: _nameOpen,
                    title: const Text('بحث بالاسم'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم الإعلان أو الكلمات المفتاحية',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  ExpansionTile(
                    initiallyExpanded: _locationOpen,
                    title: const Text('بحث حسب المدينة والمنطقة'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // City dropdown
                            InputDecorator(
                              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'المحافظة'),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedCity,
                                  hint: const Text('اختر المحافظة'),
                                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedCity = v;
                                      _selectedRegion = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Region dropdown (depends on selected city)
                            InputDecorator(
                              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'المنطقة'),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedRegion,
                                  hint: const Text('اختر المنطقة'),
                                  items: _selectedCity != null && _regionsByCity[_selectedCity] != null
                                      ? _regionsByCity[_selectedCity]!.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList()
                                      : [],
                                  onChanged: (v) => setState(() => _selectedRegion = v),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  ExpansionTile(
                    initiallyExpanded: _advancedOpen,
                    title: const Text('بحث متقدم'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Categories and subcategories
                            const Text('التصنيف'),
                            const SizedBox(height: 8),
                            InputDecorator(
                              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'القسم الرئيسي'),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedCategory,
                                  hint: const Text('اختر القسم'),
                                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedCategory = v;
                                      _selectedSubCategory = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'التصنيف الفرعي'),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedSubCategory,
                                  hint: const Text('اختر التصنيف الفرعي'),
                                  items: _selectedCategory != null && _subcats[_selectedCategory] != null
                                      ? _subcats[_selectedCategory]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList()
                                      : [],
                                  onChanged: (v) => setState(() => _selectedSubCategory = v),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Currency
                            InputDecorator(
                              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'العملة'),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedCurrency,
                                  hint: const Text('اختر العملة'),
                                  items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (v) => setState(() => _selectedCurrency = v),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Sale type and delivery
                            Row(
                              children: [
                                Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'نوع الإعلان'),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _saleType,
                                        items: const [
                                          DropdownMenuItem(value: 'sale', child: Text('للبيع')),
                                          DropdownMenuItem(value: 'rent', child: Text('للإيجار')),
                                        ],
                                        onChanged: (v) => setState(() => _saleType = v ?? 'sale'),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'التوصيل'),
                                    child: SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(_delivery ? 'مع توصيل' : 'بدون توصيل'),
                                      value: _delivery,
                                      onChanged: (v) => setState(() => _delivery = v),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Price range
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _minPrice,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'الحد الأدنى للسعر'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _maxPrice,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'الحد الأقصى للسعر'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Fixed bottom bar with Search and Cancel
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: return search criteria or perform search
                        Navigator.of(context).pop();
                      },
                      child: const Text('بحث'),
                    ),
                  ),
                ],
              ),
            ),
          ],
            ),
          ),
          if (_loadingOptions)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
