import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../../../../core/ui/notifications.dart';
import '../../data/models/app_options.dart';
import '../../data/services/options_service.dart';
import 'search_results_screen.dart';

class SearchOptionsScreen extends StatefulWidget {
  const SearchOptionsScreen({Key? key}) : super(key: key);

  @override
  State<SearchOptionsScreen> createState() => _SearchOptionsScreenState();
}

enum SearchMode { name, location, advanced }

class _SearchOptionsScreenState extends State<SearchOptionsScreen> with SingleTickerProviderStateMixin {
  // state
  SearchMode _mode = SearchMode.name;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  Timer? _suggestTimer;
  List<String> _suggestions = [];
  bool _loadingSuggestions = false;
  String? _nameError;

  int? _selectedCityId;
  int? _selectedRegionId;
  String? _cityError;
  String? _regionError;

  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  String? _categoryError;
  String? _subCategoryError;
  int? _selectedCurrencyId;
  String _saleType = 'sale';
  bool _delivery = false;
  final TextEditingController _minPrice = TextEditingController();
  final TextEditingController _maxPrice = TextEditingController();

  AppOptions? _options;
  bool _loadingOptions = false;

  late final TabController _tabController;

  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _advancedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: _mode.index);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final newMode = SearchMode.values[_tabController.index];
      if (mounted) setState(() => _mode = newMode);
      if (newMode == SearchMode.name) {
        WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(_nameFocus));
      }
    }
  }

  Future<void> _loadOptions() async {
    if (mounted) setState(() => _loadingOptions = true);
    final notifyCtx = context;
    try {
      Notifications.showLoading(notifyCtx, message: 'جاري التحميل...');
      final dio = Dio(BaseOptions(receiveTimeout: const Duration(seconds: 20), connectTimeout: const Duration(seconds: 20)));
      final service = OptionsService(dio);
      final opts = await service.fetchOptions();
      if (!mounted) return;
      setState(() {
        _options = opts;
        _loadingOptions = false;
      });
      Notifications.hideLoading(notifyCtx);
    } catch (e) {
      try {
        Notifications.hideLoading(notifyCtx);
      } catch (_) {}
      if (mounted) setState(() => _loadingOptions = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      Notifications.showError(context, msg);
    }
  }

  Future<void> _fetchSuggestions(String q) async {
    try {
      final dio = Dio();
      final resp = await dio.get('https://sahbo-app-api.onrender.com/api/ads/suggested-ads', queryParameters: {'q': q, 'limit': 5});
      final data = resp.data as List<dynamic>?;
      if (!mounted) return;
      setState(() {
        _suggestions = data != null ? data.map((e) => e.toString()).toList() : [];
        _loadingSuggestions = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
    }
  }

  void _clearName() {
    _nameController.clear();
    _suggestions = [];
    _nameError = null;
  }

  void _clearLocation() {
    _selectedCityId = null;
    _selectedRegionId = null;
    _cityError = null;
    _regionError = null;
  }

  void _clearAdvanced() {
    _selectedCategoryId = null;
    _selectedSubCategoryId = null;
    _categoryError = null;
    _subCategoryError = null;
    _selectedCurrencyId = null;
    _saleType = 'sale';
    _delivery = false;
    _minPrice.clear();
    _maxPrice.clear();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    _suggestTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بحث')),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Tab headers
                SizedBox(
                  height: 48,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.onPrimary,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
                    tabs: const [
                      Tab(text: 'اسم'),
                      Tab(text: 'محافظة/منطقة'),
                      Tab(text: 'متقدم'),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Name
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: _nameKey,
                                  focusNode: _nameFocus,
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    labelText: 'ابحث بالاسم',
                                    errorText: _nameError,
                                  ),
                                  onChanged: (v) {
                                    if (_nameError != null && v.trim().isNotEmpty) {
                                      if (mounted) setState(() => _nameError = null);
                                    }
                                    _suggestTimer?.cancel();
                                    if (v.trim().isEmpty) {
                                      if (mounted) setState(() {
                                        _suggestions = [];
                                        _loadingSuggestions = false;
                                      });
                                      return;
                                    }
                                    if (mounted) setState(() => _loadingSuggestions = true);
                                    _suggestTimer = Timer(const Duration(milliseconds: 350), () async {
                                      await _fetchSuggestions(v.trim());
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(width: 28, height: 28, child: _loadingSuggestions ? const CircularProgressIndicator(strokeWidth: 2) : const SizedBox()),
                            ],
                          ),

                          const SizedBox(height: 8),
                          if (_suggestions.isNotEmpty)
                            Card(
                              elevation: 1,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (ctx, i) {
                                  final s = _suggestions[i];
                                  return ListTile(
                                    title: Text(s),
                                    onTap: () {
                                      if (mounted) setState(() {
                                        _nameController.text = s;
                                        _suggestions = [];
                                        _nameError = null;
                                      });
                                    },
                                  );
                                },
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemCount: _suggestions.length,
                              ),
                            ),
                        ],
                      ),

                      // Location
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          Padding(
                            key: _locationKey,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InputDecorator(
                                  decoration: InputDecoration(labelText: 'المحافظة', errorText: _cityError),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: _selectedCityId,
                                      hint: const Text('اختر المحافظة'),
                                      items: (_options?.provinces ?? []).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                                      onChanged: (v) {
                                        if (mounted) setState(() {
                                          _selectedCityId = v;
                                          _selectedRegionId = null;
                                          _cityError = null;
                                          _regionError = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InputDecorator(
                                  decoration: InputDecoration(labelText: 'المنطقة', errorText: _regionError),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: _selectedRegionId,
                                      hint: const Text('اختر المنطقة'),
                                      items: (_options?.majorAreas.where((a) => a.provinceId == _selectedCityId).toList() ?? [])
                                          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                                          .toList(),
                                      onChanged: (v) {
                                        if (mounted) setState(() {
                                          _selectedRegionId = v;
                                          _regionError = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Advanced
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          Padding(
                            key: _advancedKey,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('التصنيف'),
                                const SizedBox(height: 8),
                                InputDecorator(
                                  decoration: InputDecoration(labelText: 'التصنيف الرئيسي', errorText: _categoryError),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: _selectedCategoryId,
                                      hint: const Text('اختر القسم'),
                                      items: (_options?.categories ?? []).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                      onChanged: (v) {
                                        if (mounted) setState(() {
                                          _selectedCategoryId = v;
                                          _selectedSubCategoryId = null;
                                          _categoryError = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InputDecorator(
                                  decoration: InputDecoration(labelText: 'التصنيف الفرعي', errorText: _subCategoryError),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: _selectedSubCategoryId,
                                      hint: const Text('اختر التصنيف الفرعي'),
                                      items: (_options?.subCategories.where((s) => s.categoryId == _selectedCategoryId).toList() ?? [])
                                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                                          .toList(),
                                      onChanged: (v) {
                                        if (mounted) setState(() {
                                          _selectedSubCategoryId = v;
                                          _subCategoryError = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InputDecorator(
                                  decoration: const InputDecoration(labelText: 'العملة'),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: _selectedCurrencyId,
                                      hint: const Text('اختر العملة'),
                                      items: (_options?.currencies ?? []).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                      onChanged: (v) {
                                        if (mounted) setState(() => _selectedCurrencyId = v);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InputDecorator(
                                        decoration: const InputDecoration(labelText: 'نوع الإعلان'),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isExpanded: true,
                                            value: _saleType,
                                            items: const [
                                              DropdownMenuItem(value: 'sale', child: Text('للبيع')),
                                              DropdownMenuItem(value: 'rent', child: Text('للإيجار')),
                                            ],
                                            onChanged: (v) {
                                              if (mounted) setState(() => _saleType = v ?? 'sale');
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InputDecorator(
                                        decoration: const InputDecoration(labelText: 'التوصيل'),
                                        child: SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(_delivery ? 'مع توصيل' : 'بدون توصيل'),
                                          value: _delivery,
                                          onChanged: (v) {
                                            if (mounted) setState(() => _delivery = v);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _minPrice,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'الحد الأدنى للسعر'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _maxPrice,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'الحد الأقصى للسعر'),
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            // Name mode
                            if (_mode == SearchMode.name) {
                              final query = _nameController.text.trim();
                              if (query.isEmpty) {
                                if (mounted) setState(() => _nameError = 'أدخل كلمة للبحث');
                                return;
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  if (!mounted) return;
                                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SearchResultsScreen(title: query)));
                                });
                              });
                              return;
                            }

                            // Location mode
                            if (_mode == SearchMode.location) {
                              final cityErr = _selectedCityId == null ? 'اختر المحافظة' : null;
                              final regionErr = _selectedRegionId == null ? 'اختر المنطقة' : null;
                              if (cityErr != null || regionErr != null) {
                                if (mounted) setState(() {
                                  _cityError = cityErr;
                                  _regionError = regionErr;
                                });
                                return;
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  if (!mounted) return;
                                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SearchResultsScreen(cityId: _selectedCityId, regionId: _selectedRegionId)));
                                });
                              });
                              return;
                            }

                            // Advanced mode
                            if (_mode == SearchMode.advanced) {
                              final catErr = _selectedCategoryId == null ? 'اختر القسم' : null;
                              final subErr = _selectedSubCategoryId == null ? 'اختر التصنيف الفرعي' : null;
                              if (catErr != null || subErr != null) {
                                if (mounted) setState(() {
                                  _categoryError = catErr;
                                  _subCategoryError = subErr;
                                });
                                return;
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  if (!mounted) return;
                                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SearchResultsScreen(
                                    categoryId: _selectedCategoryId,
                                    subCategoryId: _selectedSubCategoryId,
                                    forSale: _saleType == 'sale' ? 'true' : 'false',
                                    deliveryService: _delivery ? 'true' : 'false',
                                    priceMin: _minPrice.text.isNotEmpty ? _minPrice.text : null,
                                    priceMax: _maxPrice.text.isNotEmpty ? _maxPrice.text : null,
                                    currencyId: _selectedCurrencyId,
                                  )));
                                });
                              });
                              return;
                            }

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
