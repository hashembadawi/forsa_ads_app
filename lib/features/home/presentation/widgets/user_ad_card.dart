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

  Widget _buildTypeBadge() {
    final label = ad.forSale ? 'للبيع' : 'للإيجار';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildDeliveryBadge() {
    if (ad.deliveryService) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          border: Border.all(color: Colors.green.withOpacity(0.18)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('توصيل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('بدون توصيل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image on the right
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 72, height: 72, child: _buildImage()),
              ),

              const SizedBox(width: 12),

              // Textual details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      ad.adTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),

                    // Currency then price
                    Align(
                      alignment: Alignment.centerRight,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ad.currencyName, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Text(_formatPrice(ad.price), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 1),

                    // Time row
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(_getTimeAgo(ad.createDate), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ]),
                    ),
                    const SizedBox(height: 2),

                    // Approval status
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(ad.isApproved ? Icons.verified_outlined : Icons.hourglass_bottom_rounded, size: 12, color: ad.isApproved ? Colors.green : AppTheme.warningColor),
                        const SizedBox(width: 4),
                        Text(ad.isApproved ? 'تمت الموافقة من الإدارة' : 'قيد المراجعة', style: TextStyle(fontSize: 11, color: ad.isApproved ? Colors.green : AppTheme.warningColor, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            // Opposite-side badges (delivery and type)
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDeliveryBadge(),
                const SizedBox(height: 6),
                _buildTypeBadge(),
              ],
            ),
          ],
          ),
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
