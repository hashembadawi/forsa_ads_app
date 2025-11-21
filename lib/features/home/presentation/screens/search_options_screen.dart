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

class _SearchOptionsScreenState extends State<SearchOptionsScreen> {
  // UI state for accordions
  bool _nameOpen = true;
  bool _locationOpen = false;
  bool _advancedOpen = false;

  // Example fields (populated later by backend)
  final TextEditingController _nameController = TextEditingController();
  Timer? _suggestTimer;
  List<String> _suggestions = [];
  bool _loadingSuggestions = false;
  int? _selectedCityId;
  int? _selectedRegionId;
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  int? _selectedCurrencyId;
  String _saleType = 'sale'; // or 'rent'
  bool _delivery = false;
  final TextEditingController _minPrice = TextEditingController();
  final TextEditingController _maxPrice = TextEditingController();

  // Options model populated from backend
  AppOptions? _options;
  // Keys for scrolling to expanded sections
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _advancedKey = GlobalKey();

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
      Notifications.showLoading(notifyCtx, message: 'جاري التحميل...');
      final dio = Dio(BaseOptions(receiveTimeout: const Duration(seconds: 20), connectTimeout: const Duration(seconds: 20)));
      final service = OptionsService(dio);
      final options = await service.fetchOptions();

      setState(() {
        _options = options;
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

  Future<void> _fetchSuggestions(String q) async {
    try {
      final dio = Dio();
      final resp = await dio.get('https://sahbo-app-api.onrender.com/api/ads/suggested-ads', queryParameters: {'q': q, 'limit': 5});
      final data = resp.data as List<dynamic>?;
      setState(() {
        _suggestions = data != null ? data.map((e) => e.toString()).toList() : [];
        _loadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    _suggestTimer?.cancel();
    super.dispose();
  }

  // Helpers to clear fields when switching search mode
  void _clearName() {
    _nameController.clear();
    _suggestions = [];
  }

  void _clearLocation() {
    _selectedCityId = null;
    _selectedRegionId = null;
  }

  void _clearAdvanced() {
    _selectedCategoryId = null;
    _selectedSubCategoryId = null;
    _selectedCurrencyId = null;
    _saleType = 'sale';
    _delivery = false;
    _minPrice.clear();
    _maxPrice.clear();
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
                  ExpansionPanelList.radio(
                    initialOpenPanelValue: _nameOpen ? 'name' : (_locationOpen ? 'location' : (_advancedOpen ? 'advanced' : null)),
                    expansionCallback: (index, isExpanded) {
                      setState(() {
                        if (index == 0) {
                          _nameOpen = !isExpanded;
                          _locationOpen = false;
                          _advancedOpen = false;
                          if (_nameOpen) {
                            _clearLocation();
                            _clearAdvanced();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final ctx = _nameKey.currentContext;
                              if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
                            });
                          }
                        } else if (index == 1) {
                          _locationOpen = !isExpanded;
                          _nameOpen = false;
                          _advancedOpen = false;
                          if (_locationOpen) {
                            _clearName();
                            _clearAdvanced();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final ctx = _locationKey.currentContext;
                              if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
                            });
                          }
                        } else if (index == 2) {
                          _advancedOpen = !isExpanded;
                          _nameOpen = false;
                          _locationOpen = false;
                          if (_advancedOpen) {
                            _clearName();
                            _clearLocation();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final ctx = _advancedKey.currentContext;
                              if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
                            });
                          }
                        }
                      });
                    },
                    children: [
                      ExpansionPanelRadio(
                        value: 'name',
                        canTapOnHeader: true,
                        headerBuilder: (ctx, isOpen) => Container(
                          color: Theme.of(ctx).colorScheme.primary.withOpacity(0.06),
                          child: const ListTile(title: Text('بحث بالاسم')),
                        ),
                        body: Padding(
                          key: _nameKey,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'اسم الإعلان أو الكلمات المفتاحية',
                                      ),
                                      onChanged: (v) {
                                        // debounce suggestions
                                        _suggestTimer?.cancel();
                                        if (v.trim().isEmpty) {
                                          setState(() {
                                            _suggestions = [];
                                            _loadingSuggestions = false;
                                          });
                                          return;
                                        }
                                        setState(() => _loadingSuggestions = true);
                                        _suggestTimer = Timer(const Duration(milliseconds: 350), () async {
                                          await _fetchSuggestions(v.trim());
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: _loadingSuggestions ? const CircularProgressIndicator(strokeWidth: 2) : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              if (_suggestions.isNotEmpty) ...[
                                const SizedBox(height: 8),
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
                                          setState(() {
                                            _nameController.text = s;
                                            _suggestions = [];
                                          });
                                        },
                                      );
                                    },
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemCount: _suggestions.length,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // expansion handled by ExpansionPanelList.radio.expansionCallback
                      ),
                      ExpansionPanelRadio(
                        value: 'location',
                        canTapOnHeader: true,
                        headerBuilder: (ctx, isOpen) => Container(
                          color: Theme.of(ctx).colorScheme.secondary.withOpacity(0.06),
                          child: const ListTile(title: Text('بحث حسب المدينة والمنطقة')),
                        ),
                        body: Padding(
                          key: _locationKey,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // City dropdown (Province)
                              InputDecorator(
                                decoration: const InputDecoration(labelText: 'المحافظة'),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _selectedCityId,
                                    hint: const Text('اختر المحافظة'),
                                    items: (_options?.provinces ?? []).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _selectedCityId = v;
                                        _selectedRegionId = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Region dropdown (depends on selected province)
                              InputDecorator(
                                decoration: const InputDecoration(labelText: 'المنطقة'),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _selectedRegionId,
                                    hint: const Text('اختر المنطقة'),
                                    items: (_options?.majorAreas.where((a) => a.provinceId == _selectedCityId).toList() ?? [])
                                        .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedRegionId = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // expansion handled by ExpansionPanelList.radio.expansionCallback
                      ),
                      ExpansionPanelRadio(
                        value: 'advanced',
                        canTapOnHeader: true,
                        headerBuilder: (ctx, isOpen) => Container(
                          color: Theme.of(ctx).colorScheme.tertiary.withOpacity(0.06),
                          child: const ListTile(title: Text('بحث متقدم')),
                        ),
                        body: Padding(
                          key: _advancedKey,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Categories and subcategories
                              const Text('التصنيف'),
                              const SizedBox(height: 8),
                              InputDecorator(
                                decoration: const InputDecoration(labelText: 'القسم الرئيسي'),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _selectedCategoryId,
                                    hint: const Text('اختر القسم'),
                                    items: (_options?.categories ?? []).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _selectedCategoryId = v;
                                        _selectedSubCategoryId = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              InputDecorator(
                                decoration: const InputDecoration(labelText: 'التصنيف الفرعي'),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _selectedSubCategoryId,
                                    hint: const Text('اختر التصنيف الفرعي'),
                                    items: (_options?.subCategories.where((s) => s.categoryId == _selectedCategoryId).toList() ?? [])
                                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedSubCategoryId = v),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Currency
                              InputDecorator(
                                decoration: const InputDecoration(labelText: 'العملة'),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _selectedCurrencyId,
                                    hint: const Text('اختر العملة'),
                                    items: (_options?.currencies ?? []).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                    onChanged: (v) => setState(() => _selectedCurrencyId = v),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Sale type and delivery
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
                                          onChanged: (v) => setState(() => _saleType = v ?? 'sale'),
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
                        // expansion handled by ExpansionPanelList.radio.expansionCallback
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
                        // If name mode is selected, navigate to results screen
                        if (_nameOpen) {
                          final query = _nameController.text.trim();
                          if (query.isEmpty) {
                            Notifications.showSnack(context, 'أدخل كلمة للبحث');
                            return;
                          }
                          // schedule navigation after current frame/animations complete
                          // add a small delay to avoid navigator locked errors during other transitions
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            // small delay to avoid navigator locked assertions
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (!mounted) return;
                              Navigator.of(context).pushReplacement(MaterialPageRoute(
                                builder: (_) => SearchResultsScreen(title: query),
                              ));
                            });
                          });
                          return;
                        }

                        // For other modes we'll just pop for now (search wiring later)
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
