import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shimmer/shimmer.dart';
import '../../data/models/user_ad.dart';
import '../../../../core/theme/app_theme.dart';

class HomeAdCard extends StatelessWidget {
  // Aspect ratio tuned for a compact horizontal row
  static const double kGridAspectRatio = 4.0;

  final UserAd ad;

  const HomeAdCard({super.key, required this.ad});

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
      var cleanBase64 = base64String;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      // remove any whitespace/newlines and non-base64 characters
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'[^A-Za-z0-9+/=_-]'), '');

      // Try decode; if fails, attempt padding fixes
      try {
        return Uint8List.fromList(base64.decode(cleanBase64));
      } catch (_) {}

      var padded = cleanBase64;
      while (padded.length % 4 != 0) {
        padded += '=';
        if (padded.length > cleanBase64.length + 4) break;
      }
      try {
        return Uint8List.fromList(base64.decode(padded));
      } catch (_) {
        return Uint8List(0);
      }
    } catch (e) {
      return Uint8List(0);
    }
  }

  Widget _buildImage(BuildContext context) {
    if (ad.thumbnail.isEmpty) {
      return Container(color: Colors.grey[300]);
    }

    final bytes = _decodeBase64(ad.thumbnail);
    if (bytes.isEmpty) return Container(color: Colors.grey[300]);

    return _ImageWithShimmer(imageBytes: bytes);
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
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSpecialBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        border: Border.all(color: Colors.amber.withOpacity(0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star, size: 12, color: Colors.amber),
          SizedBox(width: 6),
          Text('مميز', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber)),
        ],
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
  Widget build(BuildContext context) {
    // Horizontal layout: text on the left, image on the right (square)
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        // Use RTL row so the card reads right-to-left and image stays on the right
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image on the right - square with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _buildImage(context),
              ),
            ),

            const SizedBox(width: 12),

            // Textual details (expand to fill remaining space) - text aligned to the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title (right-aligned)
                  Text(
                    ad.adTitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 1),

                  // Currency then price (currency first, then numeric price)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            ad.currencyName,
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatPrice(ad.price),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),

                  // Main category with icon under the price
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category_outlined, size: 12, color: Colors.black54),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ad.categoryName,
                            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),

                  // City and region (same row) placed under category and above the publish time
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Colors.black54),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ad.regionName != null && ad.regionName!.isNotEmpty
                                ? '${ad.cityName} - ${ad.regionName}'
                                : ad.cityName,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 1),

                  // Publish time with clock icon, aligned to the right
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(ad.createDate),
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Opposite-side badges: special badge (top) and type badge (below)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ad.isSpecial) _buildSpecialBadge(),
                if (ad.isSpecial) const SizedBox(height: 6),
                _buildTypeBadge(),
                const SizedBox(height: 6),
                _buildDeliveryBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
        if (_isLoading)
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.grey[300]),
          ),
        Image.memory(
          widget.imageBytes,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSync) {
            if (wasSync) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isLoading = false);
              });
              return child;
            }
            if (frame != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isLoading = false);
              });
              return AnimatedOpacity(opacity: _isLoading ? 0 : 1, duration: const Duration(milliseconds: 250), child: child);
            }
            return const SizedBox.shrink();
          },
          errorBuilder: (context, error, stack) => Container(color: Colors.grey[300]),
        ),
      ],
    );
  }
}
