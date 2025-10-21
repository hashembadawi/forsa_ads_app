import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/ui/notifications.dart';
import '../../../core/utils/network_utils.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/providers/app_state_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String password;
  const VerifyScreen({super.key, required this.phoneNumber, required this.password});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  // Four controllers for the 4-box OTP input
  final List<TextEditingController> _digitCtrls = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _digitFocus = List.generate(4, (_) => FocusNode());
  Timer? _timer;
  int _remaining = 600; // 10 minutes in seconds
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // focus the first OTP box when the screen appears
    Future.microtask(() => _digitFocus.first.requestFocus());
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = 600;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digitCtrls) {
      c.dispose();
    }
    for (final f in _digitFocus) {
      f.dispose();
    }
    super.dispose();
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Future<void> _verify() async {
    // Operation-level connectivity check: avoid performing network calls when offline.
  final connected = await NetworkUtils.ensureConnected(context);
  if (!connected) return;
  if (!mounted) return;

    final code = _digitCtrls.map((c) => c.text.trim()).join();
    if (code.length != 4) {
      Notifications.showSnack(context, 'الرجاء إدخال رمز من 4 خانات');
      return;
    }

    try {
      setState(() => _isLoading = true);
      if (!mounted) return;
      Notifications.showLoading(context, message: 'جاري التحقق...');
      final resp = await http.post(
        Uri.parse('https://sahbo-app-api.onrender.com/api/user/verify-phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': widget.phoneNumber, 'verificationCode': code}),
      );
      if (!mounted) return;
      Notifications.hideLoading(context);
      setState(() => _isLoading = false);

      if (resp.statusCode == 200) {
        // After successful verification, perform login automatically
        // Before attempting to login, verify connectivity again (network may have dropped).
        final loginConnected = await NetworkUtils.ensureConnected(context);
        if (!loginConnected) {
          if (!mounted) return;
          Notifications.hideLoading(context);
          setState(() => _isLoading = false);
          return;
        }

        if (!mounted) return;
        Notifications.showLoading(context, message: 'تسجيل الدخول...');
        final loginResp = await http.post(
          Uri.parse('https://sahbo-app-api.onrender.com/api/user/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phoneNumber': widget.phoneNumber, 'password': widget.password}),
        );
        if (!mounted) return;
        Notifications.hideLoading(context);

        if (loginResp.statusCode == 200) {
          final body = jsonDecode(loginResp.body);
          final token = body['token'] ?? '';
          final first = (body['userFirstName'] ?? '') as String;
          final last = (body['userLastName'] ?? '') as String;
          await ref.read(appStateProvider.notifier).loginUser(token: token, phone: widget.phoneNumber, firstName: first.isNotEmpty ? first : null, lastName: last.isNotEmpty ? last : null);

          final prefs = await SharedPreferences.getInstance();
          if (body.containsKey('userId')) await prefs.setString('userId', body['userId'] ?? '');
          if (body.containsKey('userPhone')) await prefs.setString('userPhone', body['userPhone'] ?? '');
          if (body.containsKey('userProfileImage')) await prefs.setString('userProfileImage', body['userProfileImage'] ?? '');
          if (body.containsKey('userAccountNumber')) await prefs.setString('userAccountNumber', body['userAccountNumber'] ?? '');
          if (body.containsKey('userIsVerified')) await prefs.setBool('userIsVerified', body['userIsVerified'] ?? false);
          if (body.containsKey('userIsAdmin')) await prefs.setBool('userIsAdmin', body['userIsAdmin'] ?? false);
          if (body.containsKey('userIsSpecial')) await prefs.setBool('userIsSpecial', body['userIsSpecial'] ?? false);

          if (mounted) {
            Notifications.showSuccess(context, 'تم تسجيل الدخول بنجاح', okText: AppStrings.ok, onOk: () {
              if (context.mounted) context.goNamed(RouteNames.home);
            });
          }
        } else {
            if (mounted) Notifications.showError(context, 'ان عملية التحقق لم تتم يرجى التحقق من الرمز');
        }
      } else {
        if (mounted) Notifications.showError(context, 'ان عملية التحقق لم تتم يرجى التحقق من الرمز');
      }
    } catch (e) {
      if (mounted) Notifications.hideLoading(context);
      if (mounted) setState(() => _isLoading = false);
      if (mounted) Notifications.showError(context, 'ان عملية التحقق لم تتم يرجى التحقق من الرمز');
    }
  }

  Future<void> _resendVerification() async {
    final connected = await NetworkUtils.ensureConnected(context);
    if (!connected) return;
    if (!mounted) return;

    try {
      setState(() => _isResending = true);
      Notifications.showLoading(context, message: 'جاري إعادة إرسال رمز التحقق...');
      final resp = await http.post(
        Uri.parse('https://sahbo-app-api.onrender.com/api/user/send-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': widget.phoneNumber}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      Notifications.hideLoading(context);
      setState(() => _isResending = false);

      if (resp.statusCode == 200) {
        Notifications.showSuccess(context, 'تم إعادة إرسال رمز التحقق', okText: AppStrings.ok);
        _startTimer(); // reset timer to 10 minutes
      } else {
        Notifications.showError(context, 'حدث خطأ بالعملية يرجى المحاولة لاحقاً');
      }
    } catch (e) {
      if (mounted) {
        Notifications.hideLoading(context);
        setState(() => _isResending = false);
        Notifications.showError(context, AppStrings.networkError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (context.mounted) {
          // go back to login
          GoRouter.of(context).pushNamed(RouteNames.login);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تأكيد الحساب'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text('أدخل رمز التحقق المرسل إلى رقم ${widget.phoneNumber}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              // Resend verification button
              TextButton(
                onPressed: _isResending ? null : _resendVerification,
                child: Text(_isResending ? 'جاري الإرسال...' : 'إعادة ارسال رمز تحقق'),
              ),
              const SizedBox(height: 8),
              Text('ستنتهي صلاحية الرمز خلال', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(_formatTime(_remaining), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 24),
              const SizedBox(height: 8),
              // Nice 4-box OTP input (force LTR order)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: SizedBox(
                        width: 56,
                        child: TextField(
                          controller: _digitCtrls[i],
                          focusNode: _digitFocus[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          maxLength: 1,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 2),
                          onChanged: (v) {
                            // If user pasted the whole code into one field
                            if (v.length > 1) {
                              final digits = v.replaceAll(RegExp(r'\D'), '');
                              for (int k = 0; k < 4; k++) {
                                _digitCtrls[k].text = k < digits.length ? digits[k] : '';
                              }
                              // unfocus last after microtask to ensure UI updates
                              Future.microtask(() => _digitFocus.last.unfocus());
                              return;
                            }

                            if (v.isNotEmpty) {
                              // move to next (schedule to avoid timing race with input)
                              if (i + 1 < _digitFocus.length) {
                                Future.microtask(() => _digitFocus[i + 1].requestFocus());
                              } else {
                                Future.microtask(() => _digitFocus[i].unfocus());
                              }
                            } else {
                              // if emptied, move to previous
                              if (i - 1 >= 0) {
                                Future.microtask(() => _digitFocus[i - 1].requestFocus());
                              }
                            }
                          },
                          onSubmitted: (_) {
                            if (i + 1 < _digitFocus.length) _digitFocus[i + 1].requestFocus();
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(text: 'تفعيل الحساب', onPressed: _isLoading ? null : _verify, isLoading: _isLoading, size: AppButtonSize.large, fullWidth: true),
            ],
          ),
        ),
      ),
    );
  }
}
