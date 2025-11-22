import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/strings.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/ui/notifications.dart';
import '../../../../core/ui/app_keys.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/ad_details.dart';
import '../widgets/home_ad_card.dart';
import '../../data/models/user_ad.dart';
import '../../data/services/user_ads_service.dart';
import 'package:dio/dio.dart';
import '../../../../core/widgets/async_image_with_shimmer.dart';
import '../../../../core/theme/app_theme.dart';

class AdDetailsScreen extends ConsumerStatefulWidget {
  final AdDetails ad;
  const AdDetailsScreen({super.key, required this.ad});

  @override
  ConsumerState<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends ConsumerState<AdDetailsScreen> {
  Uint8List? _tryDecode(String content) {
    try {
      var s = content.trim();
      if (s.contains(',')) s = s.split(',').last;
      s = s.replaceAll(RegExp(r'[^A-Za-z0-9+/=_-]'), '');
      try {
        return base64Decode(s);
      } catch (_) {}
      var padded = s;
      while (padded.length % 4 != 0) {
        padded += '=';
      }
      try {
        return base64Decode(padded);
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  String _normalizePhoneForTel(String raw) {
    var s = raw.trim();
    // keep plus if present, remove other non-digit chars
    s = s.replaceAll(RegExp(r'[^0-9+]'), '');
    if (s.isEmpty) return s;
    if (!s.startsWith('+')) s = '+$s';
    return s;
  }

  String _normalizePhoneForWhatsApp(String raw) {
    var s = raw.trim();
    // whatsapp wa.me expects digits only (no plus or symbols)
    s = s.replaceAll(RegExp(r'[^0-9]'), '');
    // remove leading zeros which may conflict with country code expectations
    while (s.startsWith('0')) {
      s = s.substring(1);
    }
    return s;
  }

  String _adLink() {
    return 'https://syria-market-web.onrender.com/${widget.ad.id}';
  }

  Future<void> _shareViaWhatsApp(String link, BuildContext ctx) async {
    final appUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(link)}');
    final webUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(link)}');
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    Notifications.showError(ctx, 'تعذر فتح واتس آب');
  }

  Future<void> _shareViaTelegram(String link, BuildContext ctx) async {
    final appUri = Uri.parse('tg://msg?text=${Uri.encodeComponent(link)}');
    final webUri = Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(link)}');
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    Notifications.showError(ctx, 'تعذر فتح تيليجرام');
  }

  Future<void> _copyLink(String link, BuildContext ctx) async {
    await Clipboard.setData(ClipboardData(text: link));
    // No UI change when copying link (silent copy per user request)
  }

  void _showShareOptions(BuildContext ctx) {
    final link = _adLink();
    showModalBottomSheet(
      context: ctx,
      builder: (sCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message, color: Color(0xFF25D366)),
              title: const Text('عبر واتس اب'),
              onTap: () {
                Navigator.of(sCtx).pop();
                _shareViaWhatsApp(link, ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send, color: Colors.blue),
              title: const Text('عبر تيليجرام'),
              onTap: () {
                Navigator.of(sCtx).pop();
                _shareViaTelegram(link, ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('نسخ الرابط'),
              onTap: () {
                Navigator.of(sCtx).pop();
                _copyLink(link, ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }


  Future<void> _submitReport(BuildContext ctx, String reason) async {
    try {
      final appState = ref.read(appStateProvider);
      final token = appState.userToken;
      if (token == null || token.isEmpty) {
        Notifications.showError(ctx, 'يجب تسجيل الدخول لإرسال بلاغ');
        return;
      }

      Notifications.showLoading(ctx, message: 'جارٍ إرسال البلاغ...');

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      final uri = Uri.parse('https://sahbo-app-api.onrender.com/api/reports/submit');
      final body = jsonEncode({
        'adId': widget.ad.id,
        'userId': userId,
        'reason': reason,
        'description': '',
      });

      // print bash of request
      final resp = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);
      Notifications.hideLoading(ctx);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final data = jsonDecode(resp.body);
          if (data is Map && data['success'] == true) {
            Notifications.showSuccess(ctx, 'تم إرسال البلاغ للإدارة');
            return;
          }
        } catch (_) {}
        // Fallback success message when backend doesn't return expected JSON
        Notifications.showSuccess(ctx, 'تم إرسال البلاغ للإدارة');
        return;
      }
      Notifications.showError(ctx, 'فشل إرسال البلاغ، حاول مرة أخرى');
    } catch (e) {
      try {
        Notifications.hideLoading(ctx);
      } catch (_) {}
      Notifications.showError(ctx, 'حدث خطأ أثناء إرسال البلاغ');
    }
  }

  void _confirmReport(BuildContext ctx) {
    final reasons = <String>[
      'محتوى غير مناسب',
      'إعلان مخادع أو احتيالي',
      'منتج مقلد أو مزيف',
      'معلومات اتصال خاطئة',
      'إعلان مكرر',
    ];

    showModalBottomSheet(
      context: ctx,
      builder: (sCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Text('اختر سبب الإبلاغ', style: Theme.of(ctx).textTheme.titleMedium)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(sCtx).pop()),
                ],
              ),
            ),
            const Divider(height: 1),
            ...reasons.map((r) {
              return ListTile(
                title: Text(r),
                onTap: () {
                  Navigator.of(sCtx).pop();
                  _submitReport(ctx, r);
                },
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  late final List<String> _allImages;
  final PageController _controller = PageController();
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  Future<void> _submitFavorite(BuildContext ctx) async {
    try {
      final appState = ref.read(appStateProvider);
      final token = appState.userToken;
      if (token == null || token.isEmpty) {
        Notifications.showError(ctx, 'يجب تسجيل الدخول لإضافة للمفضلة');
        return;
      }
      // If currently favorited -> send DELETE to remove from favorites
      if (_isFavorite) {
        Notifications.showLoading(ctx, message: 'جارٍ إزالة من المفضلة...');
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId') ?? '';
        final uri = Uri.parse('https://sahbo-app-api.onrender.com/api/favorites/delete');
        final body = jsonEncode({'userId': userId, 'adId': widget.ad.id});

        final resp = await http.delete(uri, headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }, body: body);

        Notifications.hideLoading(ctx);

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          try {
            final data = jsonDecode(resp.body);
            if (data is Map && (data['success'] == true || data['deleted'] == true)) {
              setState(() => _isFavorite = false);
              return;
            }
          } catch (_) {}
          // fallback success
          setState(() => _isFavorite = false);
          return;
        }

        // non-2xx
        try {
          final data = jsonDecode(resp.body);
                                if (data is Map && data['message'] != null) {
            Notifications.showError(ctx, data['message'].toString());
            return;
          }
        } catch (_) {}
        Notifications.showError(ctx, 'فشل إزالة من المفضلة (${resp.statusCode})');
        return;
      }

      // Otherwise, add to favorites (existing behavior)
      Notifications.showLoading(ctx, message: 'جارٍ إضافة للمفضلة...');

      final uri = Uri.parse('https://sahbo-app-api.onrender.com/api/favorites/add');
      final body = jsonEncode({'adId': widget.ad.id});

      final resp = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);

      Notifications.hideLoading(ctx);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final data = jsonDecode(resp.body);
            if (data is Map && data['success'] == true) {
            setState(() => _isFavorite = true);
            return;
          } else if (data is Map && data['message'] != null) {
            Notifications.showError(ctx, data['message'].toString());
            return;
          }
        } catch (_) {}
        // fallback success
        setState(() => _isFavorite = true);
        return;
      }

      // non-2xx
      try {
        final data = jsonDecode(resp.body);
        if (data is Map && data['message'] != null) {
          Notifications.showError(ctx, data['message'].toString());
          return;
        }
      } catch (_) {}
      Notifications.showError(ctx, 'فشل إضافة للمفضلة (${resp.statusCode})');
    } catch (e) {
      try {
        Notifications.hideLoading(ctx);
      } catch (_) {}
      Notifications.showError(ctx, 'حدث خطأ أثناء إضافة للمفضلة');
    }
  }

  Future<void> _openRelatedAd(UserAd selected) async {
    // Use appNavigatorKey if available (global navigator), otherwise local router
    final notifyCtx = appNavigatorKey.currentContext ?? context;
    final fallbackRouter = GoRouter.of(context);

    try {
      Notifications.showLoading(notifyCtx, message: 'جاري التحميل...');
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final service = UserAdsService(dio);
      final appState = ref.read(appStateProvider);
      late final AdDetails fetched;
      if (appState.isUserLoggedIn && appState.userToken != null && appState.userToken!.isNotEmpty) {
        fetched = await service.fetchAdDetailsForUser(adId: selected.id, token: appState.userToken!);
      } else {
        fetched = await service.fetchAdDetails(adId: selected.id);
      }

      Notifications.hideLoading(notifyCtx);

      final globalCtx = appNavigatorKey.currentContext;
      if (globalCtx != null) {
        // Ensure back returns to home: navigate to home first, then push details
        GoRouter.of(globalCtx).go(AppRoutes.home);
        GoRouter.of(globalCtx).push(AppRoutes.adDetails, extra: fetched);
      } else {
        // Fallback: replace current details with new details so back goes to previous screen
        try {
          fallbackRouter.go(AppRoutes.home);
        } catch (_) {}
        fallbackRouter.push(AppRoutes.adDetails, extra: fetched);
      }
    } catch (e) {
      try {
        Notifications.hideLoading(notifyCtx);
      } catch (_) {}
      final msg = e.toString().replaceFirst('Exception: ', '');
      try {
        Notifications.showError(notifyCtx, msg);
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();
    // Compose images: thumbnail first (if present) then other images
    _allImages = [];
    // Initialize favorite state from incoming ad (if provided by backend)
    try {
      _isFavorite = widget.ad.isFavorite;
    } catch (_) {}
    if (widget.ad.thumbnail.isNotEmpty) _allImages.add(widget.ad.thumbnail);
    for (final s in widget.ad.images) {
      if (s.isNotEmpty) _allImages.add(s);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(title: const Text('تفاصيل الإعلان')),
          body: Column(
            children: [
              // Image area with counter and tap-to-open
              SizedBox(
                height: 240,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _allImages.isEmpty
                        ? Container(color: Colors.grey[300])
                        : PageView.builder(
                            controller: _controller,
                            itemCount: _allImages.length,
                            onPageChanged: (i) => setState(() => _currentImageIndex = i),
                            itemBuilder: (context, index) {
                              final content = _allImages[index];
                              var s = content;
                              if (s.contains(',')) s = s.split(',').last;
                              s = s.trim().replaceAll(RegExp(r'\s+'), '');
                              final bytes = _tryDecode(s);
                              if (bytes != null) {
                                return GestureDetector(
                                  onTap: () async {
                                    // prepare bytes list
                                    final imgs = <Uint8List>[];
                                    for (final c in _allImages) {
                                      var t = c;
                                      if (t.contains(',')) t = t.split(',').last;
                                      t = t.trim().replaceAll(RegExp(r'\s+'), '');
                                      final b = _tryDecode(t);
                                      if (b != null) imgs.add(b);
                                    }
                                    if (imgs.isNotEmpty) {
                                      Navigator.of(context).push(MaterialPageRoute(
                                          builder: (_) => _FullScreenImageViewer(images: imgs, initialIndex: index)));
                                    }
                                  },
                                  child: AsyncImageWithShimmer(imageBytes: bytes, fit: BoxFit.cover),
                                );
                              }
                              return Container(color: Colors.grey[300]);
                            },
                          ),

                    // Image counter top-left
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                        child: Text('${_currentImageIndex + 1}/${_allImages.length}', style: const TextStyle(color: Colors.white)),
                      ),
                    ),

                    // Dots indicator bottom center
                    if (_allImages.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_allImages.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentImageIndex == i ? 12 : 6,
                              height: 6,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(_currentImageIndex == i ? 0.95 : 0.6), borderRadius: BorderRadius.circular(6)),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),

              // Tabs
              const SizedBox(height: 8),
              TabBar(
                tabs: const [
                  Tab(text: 'معلومات'),
                  Tab(text: 'الوصف'),
                  Tab(text: 'الموقع'),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Theme.of(context).primaryColor,
              ),

              // Tab views
              Expanded(
                child: TabBarView(
                  children: [
                    // Info tab (clean layout: no borders, separators and spacing)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Text(
                            widget.ad.adTitle,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 12),

                          // Price and currency on the same line (aligned to end/right)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(widget.ad.price.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                const SizedBox(width: 8),
                                Text(widget.ad.currencyName, style: const TextStyle(fontSize: 16, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 12),

                          // City and Region with icons
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(Icons.place, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  widget.ad.regionName != null && widget.ad.regionName!.isNotEmpty
                                      ? '${widget.ad.cityName}  •  ${widget.ad.regionName}'
                                      : widget.ad.cityName,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 12),

                          // Category and Subcategory with icon
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                const Icon(Icons.category, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.ad.categoryName}  •  ${widget.ad.subCategoryName}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 12),

                          // For sale / For rent  •  Delivery with icons
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Icon(widget.ad.forSale ? Icons.sell : Icons.house, size: 18, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(widget.ad.forSale ? 'للبيع' : 'للإيجار', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Icon(Icons.local_shipping, size: 18, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(widget.ad.deliveryService ? 'يوجد توصيل' : 'بدون توصيل', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Action buttons container (icon above label)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _showShareOptions(context),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.share, color: Colors.white, size: 22),
                                        SizedBox(height: 6),
                                        Text('مشاركة', style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                      onPressed: () async {
                                          final appState = ref.read(appStateProvider);
                                          if (!appState.isUserLoggedIn) {
                                            final ok = await Notifications.showConfirm(context, AppStrings.loginRequiredMessage, confirmText: AppStrings.loginLabel, cancelText: AppStrings.no);
                                            if (ok == true) {
                                              await context.pushNamed(RouteNames.login);
                                            }
                                            return;
                                          }
                                          await _submitFavorite(context);
                                        },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : null),
                                        const SizedBox(height: 6),
                                        const Text('تفضيل'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                      onPressed: () async {
                                        final appState = ref.read(appStateProvider);
                                        if (!appState.isUserLoggedIn) {
                                          final ok = await Notifications.showConfirm(context, AppStrings.loginRequiredMessage, confirmText: AppStrings.loginLabel, cancelText: AppStrings.no);
                                          if (ok == true) {
                                            await context.pushNamed(RouteNames.login);
                                          }
                                          return;
                                        }
                                        _confirmReport(context);
                                      },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.report, color: Colors.orange),
                                        SizedBox(height: 6),
                                        Text('ابلاغ'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Related ads section (top 5 similar ads returned by backend)
                          if (widget.ad.relatedAds.isNotEmpty) ...[
                            Text('إعلانات مشابهة', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.ad.relatedAds.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (ctx, idx) {
                                  final related = widget.ad.relatedAds[idx];
                                  return SizedBox(
                                    width: 300,
                                    child: HomeAdCard(
                                      ad: related,
                                      onTap: (selected) => _openRelatedAd(selected),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),

                    // Description tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(widget.ad.description.isNotEmpty ? widget.ad.description : '-', textAlign: TextAlign.right),
                    ),

                    // Location tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.ad.location != null && widget.ad.location!.coordinates.isNotEmpty)
                            Builder(builder: (ctx) {
                              // Use the coordinates exactly as returned by the backend.
                              // The backend stores GeoJSON Points as [longitude, latitude].
                              // We interpret accordingly: coords[0] = longitude, coords[1] = latitude.
                              final coords = widget.ad.location!.coordinates;
                              double lat = 0.0, lng = 0.0;
                              if (coords.length >= 2) {
                                lng = coords[0];
                                lat = coords[1];
                              } else if (coords.isNotEmpty) {
                                // single value: treat as latitude fallback
                                lat = coords[0];
                              }

                              void openDirections() async {
                                // Try app-first (comgooglemaps / geo), then web fallback.
                                // Use precise coordinates (lat, lng) derived from backend values.
                                final appUri = Uri.parse('comgooglemaps://?center=$lat,$lng');
                                final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
                                final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                try {
                                  if (await canLaunchUrl(appUri)) {
                                    await launchUrl(appUri, mode: LaunchMode.externalApplication);
                                    return;
                                  }
                                } catch (_) {}
                                try {
                                  if (await canLaunchUrl(geoUri)) {
                                    await launchUrl(geoUri, mode: LaunchMode.externalApplication);
                                    return;
                                  }
                                } catch (_) {}
                                if (await canLaunchUrl(webUri)) {
                                  await launchUrl(webUri, mode: LaunchMode.externalApplication);
                                  return;
                                }
                                Notifications.showError(ctx, 'تعذر فتح الخرائط');
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LocationMapWid(latitude: lat, longitude: lng, onDirectionsTap: openDirections),
                                  const SizedBox(height: 12),
                                ],
                              );
                            })
                          else
                            const Text('لا يوجد موقع متوفر'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                      onPressed: () async {
                        final raw = widget.ad.userPhone;
                        final waNumber = _normalizePhoneForWhatsApp(raw);
                        if (waNumber.isEmpty) {
                          Notifications.showError(context, 'رقم المعلن غير متوفر');
                          return;
                        }
                        final appUri = Uri.parse('whatsapp://send?phone=$waNumber');
                        final webUri = Uri.parse('https://wa.me/$waNumber');
                        try {
                          if (await canLaunchUrl(appUri)) {
                            await launchUrl(appUri, mode: LaunchMode.externalApplication);
                            return;
                          }
                        } catch (_) {}
                        try {
                          if (await canLaunchUrl(webUri)) {
                            await launchUrl(webUri, mode: LaunchMode.externalApplication);
                            return;
                          }
                        } catch (_) {}
                        Notifications.showError(context, 'تعذر فتح واتس آب');
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('دردش واتس'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final raw = widget.ad.userPhone;
                        final tel = _normalizePhoneForTel(raw);
                        if (tel.isEmpty) {
                          Notifications.showError(context, 'رقم المعلن غير متوفر');
                          return;
                        }
                        final telUri = Uri.parse('tel:$tel');
                        try {
                          if (await canLaunchUrl(telUri)) {
                            await launchUrl(telUri, mode: LaunchMode.externalApplication);
                            return;
                          }
                        } catch (_) {}
                        Notifications.showError(context, 'تعذر فتح تطبيق الهاتف');
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('اتصال'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _FullScreenImageViewer extends StatefulWidget {
  final List<Uint8List> images;
  final int initialIndex;

  const _FullScreenImageViewer({Key? key, required this.images, this.initialIndex = 0}) : super(key: key);

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageController = PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(child: Text('${_current + 1}/${widget.images.length}', style: const TextStyle(color: Colors.white))),
          )
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, index) {
          final bytes = widget.images[index];
          return InteractiveViewer(
            maxScale: 4.0,
            child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
          );
        },
      ),
    );
  }
}

// Map widget to show ad location with a directions button.
class LocationMapWid extends StatelessWidget {
  final double latitude;
  final double longitude;
  final VoidCallback onDirectionsTap;

  const LocationMapWid({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng adLocation = LatLng(latitude, longitude);
    return Container(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: adLocation,
                  zoom: 15.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('adLocation'),
                    position: adLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onTap: (_) => onDirectionsTap(),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: GestureDetector(
                onTap: onDirectionsTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.directions, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'الاتجاهات عبر خرائط جوجل',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
