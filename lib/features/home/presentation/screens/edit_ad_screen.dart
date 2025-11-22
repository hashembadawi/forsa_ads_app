import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/user_ad.dart';
import '../../data/models/currency_option.dart';
import '../../data/services/user_ads_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/notifications.dart';
import '../../../../shared/widgets/app_button.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ad.adTitle);
    _priceController = TextEditingController(text: widget.ad.price.toString());
  _currencyNameController = TextEditingController(text: widget.ad.currencyName);
  _descriptionController = TextEditingController(text: widget.ad.description);
    _forSale = widget.ad.forSale;
    _deliveryService = widget.ad.deliveryService;

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
    Notifications.showLoading(context, message: 'جاري حذف الإعلان...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      if (token == null) {
        if (mounted) {
          Notifications.hideLoading(context);
          Notifications.showError(context, 'انتهت الجلسة، يرجى تسجيل الدخول');
        }
        return;
      }

      final service = UserAdsService(Dio());
      await service.deleteAd(adId: widget.ad.id, token: token);

      if (mounted) {
        Notifications.hideLoading(context);
        Notifications.showSuccess(context, 'تم حذف الإعلان بنجاح', onOk: () {
          Navigator.of(context).pop(true); // Return true to indicate deletion after OK
        });
      }
    } catch (e) {
      if (mounted) {
        Notifications.hideLoading(context);
        Notifications.showSnack(
          context,
          'حدث خطأ أثناء حذف الإعلان',
          type: NotificationType.error,
          icon: Icons.error,
        );
      }
    }
  }

  Future<void> _updateAd() async {
    // Validate all required fields before form validation
    // final title/price/description values are validated by the Form fields below
    // Use Form validators to show messages under fields instead of SnackBars.
    // Update title length requirement: must be more than 2 characters.
    if (!_formKey.currentState!.validate()) {
      // If form is invalid, the validators will show errorText under fields.
      return;
    }

    Notifications.showLoading(context, message: 'جاري تعديل الإعلان...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      if (token == null) {
        if (mounted) {
          Notifications.hideLoading(context);
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
        Notifications.hideLoading(context);
        Notifications.showSuccess(context, 'تم تعديل الإعلان بنجاح', onOk: () {
          Navigator.of(context).pop(true); // Return true to indicate update after OK
        });
      }
    } catch (e) {
      if (mounted) {
        Notifications.hideLoading(context);
        Notifications.showSnack(
          context,
          'حدث خطأ أثناء تعديل الإعلان',
          type: NotificationType.error,
          icon: Icons.error,
        );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الإعلان',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال عنوان الإعلان';
                        }
                        if (value.trim().length < 2) {
                          return 'العنوان يجب أن يكون حرفين على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Price and Currency in one row
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _currencyId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'العملة',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            menuMaxHeight: 300,
                            selectedItemBuilder: (context) {
                              return _currencies.map((c) {
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList();
                            },
                            items: _currencies
                                .map((c) => DropdownMenuItem<int>(
                                      value: c.id,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'الوصف',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال وصف الإعلان';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    // Switches
                    SwitchListTile(
                      title: const Text('للبيع'),
                      subtitle: const Text('إذا كان الإعلان للإيجار، قم بإلغاء التحديد'),
                      value: _forSale,
                      onChanged: (v) => setState(() => _forSale = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('خدمة التوصيل'),
                      subtitle: const Text('هل تقدم خدمة توصيل للمنتج؟'),
                      value: _deliveryService,
                      onChanged: (v) => setState(() => _deliveryService = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 20),

                    // Update button
                    AppButton(
                      text: 'تعديل الإعلان',
                      onPressed: _updateAd,
                      fullWidth: true,
                      size: AppButtonSize.large,
                    ),
                    const SizedBox(height: 12),

                    // Delete button
                    AppButton.outlined(
                      text: 'حذف الإعلان',
                      onPressed: _showDeleteConfirmation,
                      fullWidth: true,
                      size: AppButtonSize.large,
                      textColor: AppTheme.errorColor,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
