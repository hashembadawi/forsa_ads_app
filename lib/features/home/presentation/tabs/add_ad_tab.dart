import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';

class AddAdTab extends StatelessWidget {
  const AddAdTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navAddAd)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 64, color: AppTheme.textSecondaryColor),
            SizedBox(height: 16),
            Text(AppStrings.addAdEmpty),
          ],
        ),
      ),
    );
  }
}
