import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_button.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String title;
  final String message;

  const NoInternetWidget({
    Key? key,
    required this.onRetry,
    this.title = 'لا يوجد اتصال بالإنترنت',
    this.message = 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 80,
            color: AppTheme.iconInactiveColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'إعادة المحاولة',
            icon: Icons.refresh,
            size: AppButtonSize.large,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
