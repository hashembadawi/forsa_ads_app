import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/ui/notifications.dart';
import '../../../core/utils/network_utils.dart';
import '../../../core/constants/strings.dart';
import '../../../shared/widgets/tajawal_text.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/router/app_router.dart';

// Clean, single RegisterScreen implementation
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _countrySearchCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pickedImageFile;
  String? _pickedImageBase64;
  final FocusNode _phoneFocusNode = FocusNode();

  String _selectedCountry = 'SY';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final List<Map<String, String>> _countryList = [
    {'code': 'SY', 'name': 'سوريا', 'dial': '+963', 'flag': '🇸🇾'},
    {'code': 'TR', 'name': 'تركيا', 'dial': '+90', 'flag': '🇹🇷'},
    {'code': 'LB', 'name': 'لبنان', 'dial': '+961', 'flag': '🇱🇧'},
    {'code': 'JO', 'name': 'الأردن', 'dial': '+962', 'flag': '🇯🇴'},
    {'code': 'IQ', 'name': 'العراق', 'dial': '+964', 'flag': '🇮🇶'},
    {'code': 'EG', 'name': 'مصر', 'dial': '+20', 'flag': '🇪🇬'},
    {'code': 'DE', 'name': 'ألمانيا', 'dial': '+49', 'flag': '🇩🇪'},
    {'code': 'SE', 'name': 'السويد', 'dial': '+46', 'flag': '🇸🇪'},
    {'code': 'NL', 'name': 'هولندا', 'dial': '+31', 'flag': '🇳🇱'},
    {'code': 'AT', 'name': 'النمسا', 'dial': '+43', 'flag': '🇦🇹'},
    {'code': 'NO', 'name': 'النرويج', 'dial': '+47', 'flag': '🇳🇴'},
    {'code': 'DK', 'name': 'الدنمارك', 'dial': '+45', 'flag': '🇩🇰'},
    {'code': 'FR', 'name': 'فرنسا', 'dial': '+33', 'flag': '🇫🇷'},
    {'code': 'BE', 'name': 'بلجيكا', 'dial': '+32', 'flag': '🇧🇪'},
    {'code': 'CH', 'name': 'سويسرا', 'dial': '+41', 'flag': '🇨🇭'},
    {'code': 'GR', 'name': 'اليونان', 'dial': '+30', 'flag': '🇬🇷'},
    {'code': 'CA', 'name': 'كندا', 'dial': '+1', 'flag': '🇨🇦'},
    {'code': 'US', 'name': 'الولايات المتحدة الأمريكية', 'dial': '+1', 'flag': '🇺🇸'},
    {'code': 'AU', 'name': 'أستراليا', 'dial': '+61', 'flag': '🇦🇺'},
    {'code': 'SA', 'name': 'السعودية', 'dial': '+966', 'flag': '🇸🇦'},
    {'code': 'AE', 'name': 'الإمارات', 'dial': '+971', 'flag': '🇦🇪'},
    {'code': 'QA', 'name': 'قطر', 'dial': '+974', 'flag': '🇶🇦'},
    {'code': 'KW', 'name': 'الكويت', 'dial': '+965', 'flag': '🇰🇼'},
  ];

  List<Map<String, String>> _filteredCountries = [];

  // Render flag: use asset for Syria (edited flag) and emoji fallback for others
  Widget _renderFlag(String code, String? emoji, {double size = 23}) {
    // Make Syria's flag slightly larger for emphasis.
    final double finalSize = (code == 'SY') ? size + 6.0 : size;

    if (code == 'SY') {
      return Image.asset(
        'assets/flags/sy.png',
        width: finalSize,
        height: finalSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(emoji ?? '', style: TextStyle(fontSize: finalSize));
        },
      );
    }
    return Text(emoji ?? '', style: TextStyle(fontSize: finalSize));
  }

  // Format dial so the '+' appears to the right of the digits (e.g. 963+ instead of +963)
  String _formatDial(String dial) {
    final d = dial.trim();
    if (d.isEmpty) return '';
    final body = d.startsWith('+') ? d.substring(1) : d;
    return '$body+';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneFocusNode.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _countrySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    // Example: include _pickedImageBase64 in the payload when endpoint is provided
    if (!_formKey.currentState!.validate()) return;
    // ensure we have network before attempting registration
    final ok = await NetworkUtils.ensureConnected(context);
    if (!ok) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    Notifications.showLoading(context, message: 'جاري إنشاء الحساب...');
    try {
      // Build full phone number without '+' by concatenating country dial (digits only) and the entered phone digits
      final selected = _countryList.firstWhere((c) => c['code'] == _selectedCountry, orElse: () => {'dial': ''});
      final dial = (selected['dial'] ?? '').replaceAll('+', '');
      final phoneDigits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
      final fullPhone = '$dial$phoneDigits';

      final payload = {
        'phoneNumber': fullPhone,
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'profileImage': _pickedImageBase64 ?? ''
      };

  final resp = await http.post(Uri.parse('https://sahbo-app-api.onrender.com/api/user/register-phone'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
  if (!mounted) return;
  Notifications.hideLoading(context);
  setState(() => _isLoading = false);

      if (resp.statusCode == 201) {
        if (mounted) {
          Notifications.showSuccess(context, 'تم انشاء الحساب بنجاح', okText: 'موافق', onOk: () {
            // navigate to verification screen using go_router, pass phone+password in extra
            // pass sanitized phone (no '+') to verification screen
            if (context.mounted) context.goNamed(RouteNames.verify, extra: {'phone': fullPhone, 'password': _passwordCtrl.text});
          });
        }
      } else {
        if (mounted) Notifications.showError(context, AppStrings.networkError);
      }
    } catch (e) {
      if (mounted) Notifications.hideLoading(context);
      if (mounted) setState(() => _isLoading = false);
      if (mounted) Notifications.showError(context, AppStrings.networkError);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      if (!mounted) return;
      setState(() {
        _pickedImageFile = file;
        _pickedImageBase64 = b64;
      });
    } catch (_) {
      if (mounted) Notifications.showSnack(context, AppStrings.imagePickFailed);
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImageFile = null;
      _pickedImageBase64 = null;
    });
  }

  Future<void> _showCountryPicker(BuildContext context) async {
    _filteredCountries = List.from(_countryList);
    _countrySearchCtrl.text = '';
    Timer? debounce;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return StatefulBuilder(builder: (ctx, setModalState) {
                void applyFilter(String q) {
                  final query = q.trim().toLowerCase();
                  setModalState(() {
                    if (query.isEmpty) {
                      _filteredCountries = List.from(_countryList);
                    } else {
                      _filteredCountries = _countryList.where((c) {
                        final name = (c['name'] ?? '').toLowerCase();
                        final dial = (c['dial'] ?? '');
                        return name.contains(query) || dial.contains(query) || (c['code'] ?? '').toLowerCase().contains(query);
                      }).toList();
                    }
                  });
                }

                return Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(children: [
                    const SizedBox(height: 8),
                    Container(width: 48, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                      child: TextField(
                        controller: _countrySearchCtrl,
                        decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'بحث باسم البلد أو الرمز', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), suffixIcon: _countrySearchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _countrySearchCtrl.clear(); applyFilter(''); setModalState(() {}); }) : null),
                        onChanged: (q) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 250), () => applyFilter(q)); setModalState(() {}); },
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: _filteredCountries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = _filteredCountries[index];
                          final isSelected = c['code'] == _selectedCountry;

                          Widget buildTitle() {
                            final query = _countrySearchCtrl.text.trim();
                            if (query.isEmpty) return Text(c['name'] ?? '');
                            final name = c['name'] ?? '';
                            final lower = name.toLowerCase();
                            final qLower = query.toLowerCase();
                            final idx = lower.indexOf(qLower);
                            if (idx == -1) return Text(name);
                            final before = name.substring(0, idx);
                            final match = name.substring(idx, idx + query.length);
                            final after = name.substring(idx + query.length);
                            return RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [TextSpan(text: before), TextSpan(text: match, style: TextStyle(backgroundColor: Theme.of(context).highlightColor, fontWeight: FontWeight.w600)), TextSpan(text: after)]));
                          }

                          return ListTile(
                            leading: _renderFlag(c['code'] ?? '', c['flag'], size: 22),
                            title: buildTitle(),
                            subtitle: Text(_formatDial(c['dial'] ?? '')),
                            trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                            onTap: () { setState(() { _selectedCountry = c['code'] ?? _selectedCountry; }); Navigator.of(ctx).pop(); },
                          );
                        },
                      ),
                    ),
                  ]),
                );
              });
            },
          ),
        );
      },
    );

    debounce?.cancel();
    // After the picker closes, move focus to the phone field for quick input
    if (mounted) Future.microtask(() => _phoneFocusNode.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              TajawalText.headlineSmall('إنشاء حساب جديد'),
              const SizedBox(height: 12),

              // User image picker
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(context).dividerColor,
                      backgroundImage: _pickedImageFile != null ? FileImage(File(_pickedImageFile!.path)) as ImageProvider : null,
                      child: _pickedImageFile == null ? const Icon(Icons.person, size: 44) : null,
                    ),
                    const SizedBox(height: 8),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      AppButton.text(text: AppStrings.chooseImage, onPressed: _pickImage, icon: Icons.photo_library),
                      const SizedBox(width: 8),
                      if (_pickedImageFile != null) AppButton.text(text: AppStrings.removeImage, onPressed: _removeImage, icon: Icons.delete),
                    ]),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              TextFormField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'الاسم الأول', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'اسم العائلة', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null),
              const SizedBox(height: 12),

              // Unified phone field: left = country selector, right = phone input
              TextFormField(
                controller: _phoneCtrl,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  prefixIcon: InkWell(
                    onTap: () => _showCountryPicker(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                        	_renderFlag(_countryList.firstWhere((c) => c['code'] == _selectedCountry, orElse: () => {'flag': '🌐', 'dial': '', 'code': ''})['code'] ?? '', _countryList.firstWhere((c) => c['code'] == _selectedCountry, orElse: () => {'flag': '🌐', 'dial': ''})['flag'], size: 18),
                        	const SizedBox(width: 6),
                        	Text(_formatDial(_countryList.firstWhere((c) => c['code'] == _selectedCountry, orElse: () => {'flag': '🌐', 'dial': ''})['dial'] ?? ''), style: const TextStyle(fontSize: 14)),
                        	const SizedBox(width: 6),
                        	const Icon(Icons.arrow_drop_down, size: 20),
                      ]),
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'الرجاء إدخال رقم الهاتف';
                  final digits = v.trim();
                  if (!RegExp(r'^\d+ ? ?$').hasMatch(digits) && !RegExp(r'^\d+$').hasMatch(digits)) return 'الرجاء إدخال أرقام فقط';
                  if (digits.length != 10) return 'رقم الهاتف يجب أن يتكون من 10 خانات';
                  return null;
                },
              ),

              const SizedBox(height: 12),
              TextFormField(controller: _passwordCtrl, obscureText: _obscurePassword, decoration: InputDecoration(labelText: 'كلمة المرور', border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))), validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال كلمة المرور' : (v.length < 6 ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل' : null)),
              const SizedBox(height: 12),
              TextFormField(controller: _confirmPasswordCtrl, obscureText: _obscureConfirm, decoration: InputDecoration(labelText: 'إعادة كلمة المرور', border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))), suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))), validator: (v) => (v != _passwordCtrl.text) ? 'كلمتا المرور غير متطابقتين' : null),

              const SizedBox(height: 20),
              AppButton(text: 'إنشاء حساب', onPressed: _isLoading ? null : _onSubmit, fullWidth: true, size: AppButtonSize.large),
              const SizedBox(height: 12),
              Center(child: TextButton(onPressed: () => context.goNamed(RouteNames.login), child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'))),
            ]),
          ),
        ),
      ),
    );
  }
}
