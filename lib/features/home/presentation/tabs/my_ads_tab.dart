import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';

class MyAdsTab extends StatelessWidget {
  const MyAdsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navMyAds)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: AppTheme.textSecondaryColor),
            SizedBox(height: 16),
            Text(AppStrings.myAdsEmpty),
          ],
        ),
      ),
    );
  }
}
