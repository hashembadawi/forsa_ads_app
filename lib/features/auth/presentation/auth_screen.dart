import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/app_state_provider.dart';
import '../../../shared/widgets/app_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/ui/notifications.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/network_utils.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final int? returnTab;
  const AuthScreen({super.key, this.returnTab});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _countrySearchCtrl = TextEditingController();
  String _selectedCountry = 'SY';
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
    {'code': 'KW', 'name': 'الكويت', 'dial': '+965', 'flag': '🇰🇼'}
  ];
  List<Map<String, String>> _filteredCountries = [];
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Widget _renderFlag(String code, String? emoji, {double size = 20}) {
    final double finalSize = (code == 'SY') ? size + 6.0 : size;
    if (code == 'SY') {
      return Image.asset('assets/flags/sy.png', width: finalSize, height: finalSize, fit: BoxFit.contain, errorBuilder: (context, err, st) => Text(emoji ?? '', style: TextStyle(fontSize: finalSize)));
    }
    return Text(emoji ?? '', style: TextStyle(fontSize: finalSize));
  }

  String _formatDial(String dial) {
    final d = dial.trim();
    if (d.isEmpty) return '';
    final body = d.startsWith('+') ? d.substring(1) : d;
    return '$body+';
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
                                    onTap: () { setState(() { _selectedCountry = c['code'] ?? _selectedCountry; }); Navigator.maybeOf(ctx)?.pop(); },
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
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Build full phone number: country dial (without '+') + local phone
    final selected = _countryList.firstWhere((c) => c['code'] == _selectedCountry, orElse: () => {'dial': ''});
    final dial = (selected['dial'] ?? '').replaceAll('+', '');
    final phoneLocal = _phoneController.text.trim();
    final fullPhone = '$dial$phoneLocal';

    // ensure we have network before attempting login
  final ok = await NetworkUtils.ensureConnected(context);
  if (!ok) return;
  if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    Notifications.showLoading(context);

    try {
      final uri = Uri.parse('https://sahbo-app-api.onrender.com/api/user/login');
      final body = jsonEncode({
        'phoneNumber': fullPhone,
        'password': _passwordController.text.trim(),
      });

  final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 20));

  if (!mounted) return;

  if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = data['token'] as String?;

          if (token != null) {
          final first = data.containsKey('userFirstName') ? data['userFirstName']?.toString() ?? '' : null;
          final last = data.containsKey('userLastName') ? data['userLastName']?.toString() ?? '' : null;
          await ref.read(appStateProvider.notifier).loginUser(token: token, phone: fullPhone, firstName: first?.isNotEmpty == true ? first : null, lastName: last?.isNotEmpty == true ? last : null);

          final prefs = await SharedPreferences.getInstance();
          if (data.containsKey('userId')) await prefs.setString('userId', data['userId']?.toString() ?? '');
          if (data.containsKey('userPhone')) await prefs.setString('userPhone', data['userPhone']?.toString() ?? fullPhone);
          if (data.containsKey('userProfileImage')) await prefs.setString('userProfileImage', data['userProfileImage']?.toString() ?? '');
          if (data.containsKey('userAccountNumber')) await prefs.setString('userAccountNumber', data['userAccountNumber']?.toString() ?? '');
          if (data.containsKey('userIsVerified')) await prefs.setBool('userIsVerified', data['userIsVerified'] == true);
          if (data.containsKey('userIsAdmin')) await prefs.setBool('userIsAdmin', data['userIsAdmin'] == true);
          if (data.containsKey('userIsSpecial')) await prefs.setBool('userIsSpecial', data['userIsSpecial'] == true);

          if (!mounted) return;

          Notifications.hideLoading(context);
          if (!mounted) return;
          // If the server indicates the user is not verified, navigate to the verify screen
          final isVerifiedRaw = data.containsKey('userIsVerified') ? data['userIsVerified'] : null;
          final bool isVerified = (isVerifiedRaw == true) || (isVerifiedRaw is int && isVerifiedRaw != 0);

          if (!isVerified) {
            // Ask the user to confirm they want to activate their account, then navigate to VerifyScreen.
            if (!mounted) return;
            final ok = await Notifications.showConfirm(context, 'يجب تفعيل الحساب. هل تريد الانتقال إلى صفحة التفعيل الآن؟', confirmText: AppStrings.ok, cancelText: AppStrings.cancel);
            if (ok == true) {
              // include returnTab so VerifyScreen (or the flow after verification) can redirect back if needed
              final Map<String, dynamic> extras = {'phone': fullPhone, 'password': _passwordController.text.trim()};
              if (widget.returnTab != null) extras['returnTab'] = widget.returnTab;
              if (context.mounted) GoRouter.of(context).pushNamed(RouteNames.verify, extra: extras);
            }
            return;
          }

          if (widget.returnTab != null) {
            // Return to the caller (Home) with the desired tab index
            if (context.mounted) context.pop(widget.returnTab);
          } else {
            if (context.mounted) context.go(AppConstants.homeRoute);
          }
        } else {
          if (mounted) {
            Notifications.hideLoading(context);
            Notifications.showError(context, AppStrings.genericError);
          }
        }
      } else {
        if (mounted) {
          Notifications.hideLoading(context);
          try {
            final data = jsonDecode(resp.body) as Map<String, dynamic>;
            final err = (data['error'] ?? data['message'] ?? '').toString().toLowerCase();
            if (resp.statusCode == 500 || err.contains('invalid')) {
              Notifications.showError(context, AppStrings.invalidCredentials);
            } else {
              Notifications.showError(context, data['message']?.toString() ?? AppStrings.genericError);
            }
          } catch (_) {
            Notifications.showError(context, AppStrings.networkError);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Notifications.hideLoading(context);
        Notifications.showError(context, AppStrings.networkError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onBack() {
    context.go(AppConstants.welcomeRoute);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header
                Text(
                  'تسجيل الدخول',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ادخل بياناتك لتسجيل الدخول',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Phone Input with country selector
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    // hintText removed as requested
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
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    final digits = value.trim();
                    if (digits.length != 10) {
                      return 'رقم الهاتف يجب أن يتكون من 10 خانات';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                // Password input with visibility toggle
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 6) return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Login Button (use shared AppButton)
                AppButton(
                  text: 'تسجيل الدخول',
                  onPressed: _isLoading ? null : _onLogin,
                  isLoading: _isLoading,
                  size: AppButtonSize.large,
                  variant: AppButtonVariant.filled,
                  fullWidth: true,
                ),
                const SizedBox(height: 8),
                Center(
                  child: AppButton.text(
                    text: 'ليس لديك حساب؟ إنشاء حساب جديد',
                    onPressed: () => context.goNamed(RouteNames.register),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}