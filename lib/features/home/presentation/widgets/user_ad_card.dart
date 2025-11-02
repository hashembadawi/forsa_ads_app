import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shimmer/shimmer.dart';
import '../../data/models/user_ad.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../home/data/services/options_service.dart';
import 'package:dio/dio.dart';
import '../../../../core/ui/notifications.dart';
import '../providers/user_ads_provider.dart';

class UserAdCard extends ConsumerWidget {
  // Recommended grid childAspectRatio for this card when used inside GridView.
  // Keeping it here centralizes sizing decisions related to the card.
  static const double kGridAspectRatio = 0.65;

  final UserAd ad;

  const UserAdCard({super.key, required this.ad});

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 30) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months شهر';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'منذ $years سنة';
    }
  }

  String _formatPrice(double price) {
    final formatter = intl.NumberFormat('#,###', 'ar');
    return formatter.format(price);
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      // Remove data:image prefix if exists
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',')[1];
      }
      return Uint8List.fromList(base64.decode(cleanBase64));
    } catch (e) {
      return Uint8List(0);
    }
  }

  Widget _buildImage() {
    if (ad.thumbnail.isEmpty) {
      return _buildPlaceholder();
    }

    try {
      final imageBytes = _decodeBase64(ad.thumbnail);
      if (imageBytes.isEmpty) {
        return _buildPlaceholder();
      }

      return _ImageWithShimmer(imageBytes: imageBytes);
    } catch (e) {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        _handleTap(context, ref);
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  // تم حذف شارة قيد المراجعة من الزاوية اليمنى العليا
                ],
              ),
            ),
          ),
          
          // Content section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    ad.adTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Price + Currency row (right aligned). Category hidden per design.
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Directionality(
                            // keep numbers LTR inside the small group
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Currency (right-most)
                                Text(
                                  ad.currencyName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 4),
                                // Price (after currency)
                                Flexible(
                                  child: Text(
                                    _formatPrice(ad.price),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Ultra-thin divider with minimal padding
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Theme.of(context).dividerColor.withOpacity(0.6),
                  ),
                  const SizedBox(height: 2),
                  
                  // Time info (first line)
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppTheme.iconInactiveColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _getTimeAgo(ad.createDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Location info (second line)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppTheme.iconInactiveColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ad.cityName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Approval status under location
                  Row(
                    children: [
                      Icon(
                        ad.isApproved ? Icons.verified_outlined : Icons.hourglass_bottom_rounded,
                        size: 13,
                        color: ad.isApproved ? Colors.green : AppTheme.warningColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ad.isApproved ? 'تمت الموافقة من الإدارة' : 'قيد المراجعة',
                          style: TextStyle(
                            fontSize: 11,
                            color: ad.isApproved ? Colors.green : AppTheme.warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

extension on UserAdCard {
  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    try {
      Notifications.showLoading(context, message: 'جاري التحضير...');
      final service = OptionsService(Dio());
      final currencies = await service.fetchCurrencies();
      if (!context.mounted) return;
      Notifications.hideLoading(context);
      
      // Navigate and wait for result
      final result = await context.push(AppRoutes.editAd, extra: {
        'ad': ad,
        'currencies': currencies,
      });
      
      // If edit was successful, refresh the list
      if (result == true && context.mounted) {
        ref.read(userAdsProvider.notifier).fetchUserAds(refresh: true);
      }
    } catch (e) {
      if (context.mounted) {
        Notifications.hideLoading(context);
        Notifications.showError(context, 'فشل تحميل الخيارات. يرجى المحاولة لاحقاً');
      }
    }
  }
}

// Shimmer loading widget for images
class _ImageWithShimmer extends StatefulWidget {
  final Uint8List imageBytes;

  const _ImageWithShimmer({required this.imageBytes});

  @override
  State<_ImageWithShimmer> createState() => _ImageWithShimmerState();
}

class _ImageWithShimmerState extends State<_ImageWithShimmer> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Shimmer effect while loading
        if (_isLoading)
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              color: Colors.grey[300],
            ),
          ),
        // Actual image with fade in animation
        Image.memory(
          widget.imageBytes,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isLoading = false);
              });
              return child;
            }
            if (frame != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isLoading = false);
              });
              return AnimatedOpacity(
                opacity: _isLoading ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
                child: child,
              );
            }
            return const SizedBox.shrink();
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
