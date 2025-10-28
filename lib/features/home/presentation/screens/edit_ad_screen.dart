import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/user_ad.dart';
import '../../data/models/currency_option.dart';
import '../../data/services/user_ads_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/notifications.dart';

class EditAdScreen extends StatefulWidget {
  final UserAd ad;
  final List<dynamic> currencies; // List<CurrencyOption> ideally

  const EditAdScreen({super.key, required this.ad, this.currencies = const []});

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _currencyNameController;
  late TextEditingController _descriptionController;
  int? _currencyId;
  bool _forSale = true;
  bool _deliveryService = false;
  late List<CurrencyOption> _currencies;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ad.adTitle);
    _priceController = TextEditingController(text: widget.ad.price.toString());
  _currencyNameController = TextEditingController(text: widget.ad.currencyName);
  _descriptionController = TextEditingController(text: '');
  _forSale = true;
  _deliveryService = false;

    _currencies = widget.currencies
        .map((e) => e is CurrencyOption ? e : CurrencyOption.fromJson(e as Map<String, dynamic>))
        .toList();

    // Try to resolve currency id by name
    final match = _currencies.where((c) => c.name == widget.ad.currencyName).toList();
    if (match.isNotEmpty) {
      _currencyId = match.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _currencyNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmation() async {
    final ok = await Notifications.showConfirm(
      context,
      'هل أنت متأكد من حذف هذا الإعلان؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
    );
    if (ok == true && mounted) {
      await _deleteAd();
    }
  }

  Future<void> _deleteAd() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implement delete API call
      // await ref.read(userAdsServiceProvider).deleteAd(widget.ad.id);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
        Notifications.showSnack(
          context,
          'تم حذف الإعلان بنجاح',
          type: NotificationType.success,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        Notifications.showSnack(
          context,
          'حدث خطأ أثناء حذف الإعلان',
          type: NotificationType.error,
          icon: Icons.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      if (token == null) {
        if (mounted) {
          Notifications.showError(context, 'انتهت الجلسة، يرجى تسجيل الدخول');
        }
        return;
      }

      final service = UserAdsService(Dio());
      final body = {
        'adTitle': _titleController.text.trim(),
        'price': _priceController.text.trim(),
        'currency': _currencyId,
        'currencyName': _currencyNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'forSale': _forSale,
        'deliveryService': _deliveryService,
      };
      await service.updateAd(
        adId: widget.ad.id,
        token: token,
        body: body,
      );
      
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate update
        Notifications.showSnack(
          context,
          'تم تعديل الإعلان بنجاح',
          type: NotificationType.success,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        Notifications.showSnack(
          context,
          'حدث خطأ أثناء تعديل الإعلان',
          type: NotificationType.error,
          icon: Icons.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الإعلان'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ad info card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'معلومات الإعلان',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('التصنيف', widget.ad.categoryName),
                            const SizedBox(height: 8),
                            _buildInfoRow('الموقع', widget.ad.cityName),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'الحالة',
                              widget.ad.isApproved ? 'تمت الموافقة' : 'قيد المراجعة',
                              valueColor: widget.ad.isApproved
                                  ? Colors.green
                                  : AppTheme.warningColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title field
                    Text(
                      'عنوان الإعلان',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'أدخل عنوان الإعلان',
                        prefixIcon: const Icon(Icons.title, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 2,
                      maxLength: 100,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال عنوان الإعلان';
                        }
                        if (value.trim().length < 5) {
                          return 'العنوان يجب أن يكون 5 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price and currency row
                    Row(
                      children: [
                        // Price field
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'السعر',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  prefixIcon: const Icon(
                                    Icons.attach_money,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'يرجى إدخال السعر';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) {
                                    return 'السعر غير صحيح';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Currency field (Dropdown)
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'العملة',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _currencyId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: _currencies
                                    .map((c) => DropdownMenuItem<int>(
                                          value: c.id,
                                          child: Text(c.name),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _currencyId = val;
                                    final selected = _currencies.firstWhere((c) => c.id == val, orElse: () => _currencies.first);
                                    _currencyNameController.text = selected.name;
                                  });
                                },
                                validator: (val) {
                                  if (val == null) return 'اختر العملة';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    Text(
                      'الوصف',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'أدخل وصف الإعلان',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                      maxLines: 4,
                    ),

                    const SizedBox(height: 12),

                    // Switches
                    SwitchListTile(
                      title: const Text('للبيع'),
                      value: _forSale,
                      onChanged: (v) => setState(() => _forSale = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('خدمة التوصيل'),
                      value: _deliveryService,
                      onChanged: (v) => setState(() => _deliveryService = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 32),

                    // Update button
                    ElevatedButton(
                      onPressed: _updateAd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'تعديل الإعلان',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Delete button
                    OutlinedButton(
                      onPressed: _showDeleteConfirmation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(
                          color: AppTheme.errorColor,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'حذف الإعلان',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
