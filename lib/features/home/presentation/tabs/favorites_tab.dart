import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navFavorites)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 64, color: AppTheme.iconInactiveColor),
            SizedBox(height: 16),
            Text(AppStrings.favoritesEmpty),
          ],
        ),
      ),
    );
  }
}
