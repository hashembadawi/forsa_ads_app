import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../core/ui/notifications.dart';
import '../../data/models/app_options.dart';
import '../tabs/add_ad_steps/step1_category_options.dart';
import '../tabs/add_ad_steps/step2_ad_details.dart';
import '../tabs/add_ad_steps/step3_images.dart';

class AddAdScreen extends ConsumerStatefulWidget {
  final AppOptions options;
  
  const AddAdScreen({super.key, required this.options});

  @override
  ConsumerState<AddAdScreen> createState() => _AddAdScreenState();
}

class _AddAdScreenState extends ConsumerState<AddAdScreen> {
  int _currentStep = 0;
  
  // Data collected from steps
  final Map<String, dynamic> _adData = {
    // Step 1
    'categoryId': null,
    'categoryName': null,
    'subCategoryId': null,
    'subCategoryName': null,
    'forSale': true,
    'deliveryService': false,
    
    // Step 2
    'adTitle': null,
    'price': null,
    'currencyId': null,
    'currencyName': null,
    'cityId': null,
    'cityName': null,
    'regionId': null,
    'regionName': null,
    'location': {'coordinates': [0.0, 0.0]},
    'description': null,
    
    // Step 3
    'thumbnail': null,
    'images': <String>[],
  };

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        // Validate Step 1
        return _adData['categoryId'] != null && 
               _adData['subCategoryId'] != null;
      case 1:
        // Validate Step 2
        return _adData['adTitle'] != null && 
               _adData['adTitle'].toString().trim().isNotEmpty &&
               _adData['price'] != null && 
               _adData['currencyId'] != null &&
               _adData['cityId'] != null &&
               _adData['regionId'] != null &&
               _adData['description'] != null &&
               _adData['description'].toString().trim().isNotEmpty;
      case 2:
        // Validate Step 3
        return _adData['thumbnail'] != null;
      default:
        return false;
    }
  }

  void _onStepContinue() {
    if (!_canProceedToNextStep()) {
      Notifications.showSnack(
        context,
        _getValidationMessage(),
        type: NotificationType.info,
        icon: Icons.info,
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitAd();
    }
  }

  String _getValidationMessage() {
    switch (_currentStep) {
      case 0:
        return 'يرجى اختيار التصنيف والتصنيف الفرعي';
      case 1:
        if (_adData['adTitle'] == null || _adData['adTitle'].toString().trim().isEmpty) {
          return 'يرجى إدخال عنوان الإعلان';
        }
        if (_adData['price'] == null) {
          return 'يرجى إدخال السعر';
        }
        if (_adData['currencyId'] == null) {
          return 'يرجى اختيار العملة';
        }
        if (_adData['cityId'] == null) {
          return 'يرجى اختيار المحافظة';
        }
        if (_adData['regionId'] == null) {
          return 'يرجى اختيار المنطقة';
        }
        if (_adData['description'] == null || _adData['description'].toString().trim().isEmpty) {
          return 'يرجى إدخال وصف الإعلان';
        }
        return 'يرجى إكمال جميع الحقول المطلوبة';
      case 2:
        return 'يرجى اختيار الصورة الرئيسية';
      default:
        return 'يرجى إكمال جميع الحقول المطلوبة';
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _onStepTapped(int step) {
    setState(() => _currentStep = step);
  }

  Future<void> _submitAd() async {
    // Show loading
    Notifications.showLoading(context, message: 'جاري نشر الإعلان...');
    
    try {
      // TODO: Implement submit logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (!mounted) return;
      
      Notifications.hideLoading(context);
      
      // Show success and return with index 0 (home tab)
      Notifications.showSuccess(
        context,
        'تم نشر الإعلان بنجاح',
        okText: 'موافق',
        onOk: () {
          if (mounted) {
            Navigator.of(context).pop(0); // Return to home tab
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      
      Notifications.hideLoading(context);
      Notifications.showError(context, 'حدث خطأ أثناء نشر الإعلان. يرجى المحاولة مرة أخرى');
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentStep > 0) {
      // If not on first step, go back one step
      setState(() => _currentStep--);
      return false;
    }
    
    // If on first step, show confirmation
    final shouldPop = await Notifications.showConfirm(
      context,
      'هل تريد إلغاء إضافة الإعلان؟ سيتم فقدان جميع البيانات المدخلة.',
      confirmText: 'نعم، إلغاء',
      cancelText: 'لا، المتابعة',
    );
    
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop(0); // Return to home tab
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة إعلان جديد'),
          elevation: 0,
        ),
        body: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            onStepTapped: _onStepTapped,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: _currentStep == 2 ? 'نشر الإعلان' : 'التالي',
                        onPressed: details.onStepContinue,
                        fullWidth: true,
                        size: AppButtonSize.large,
                        variant: AppButtonVariant.filled,
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton.outlined(
                          text: 'السابق',
                          onPressed: details.onStepCancel,
                          fullWidth: true,
                          size: AppButtonSize.large,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('التصنيف والخيارات'),
                content: Step1CategoryOptions(
                  adData: _adData,
                    options: widget.options,
                  onDataChanged: (key, value) {
                    setState(() => _adData[key] = value);
                  },
                ),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('معلومات الإعلان'),
                content: Step2AdDetails(
                  adData: _adData,
                    options: widget.options,
                  onDataChanged: (key, value) {
                    setState(() => _adData[key] = value);
                  },
                ),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('الصور'),
                content: Step3Images(
                  adData: _adData,
                  onDataChanged: (key, value) {
                    setState(() => _adData[key] = value);
                  },
                ),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
            ],
        ),
      ),
    );
  }
}
