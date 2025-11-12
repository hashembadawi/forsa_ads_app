import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/ad_details.dart';
import '../../../../core/widgets/async_image_with_shimmer.dart';
import '../../../../core/theme/app_theme.dart';

class AdDetailsScreen extends StatefulWidget {
  final AdDetails ad;
  const AdDetailsScreen({super.key, required this.ad});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
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

  late final List<String> _allImages;
  final PageController _controller = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Compose images: thumbnail first (if present) then other images
    _allImages = [];
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
                height: 320,
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

                          // City and Region (no frames, separated by bullet)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              widget.ad.regionName != null && widget.ad.regionName!.isNotEmpty
                                  ? '${widget.ad.cityName}  •  ${widget.ad.regionName}'
                                  : widget.ad.cityName,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 12),

                          // Category and Subcategory
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${widget.ad.categoryName}  •  ${widget.ad.subCategoryName}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 12),

                          // For sale / For rent  •  Delivery
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${widget.ad.forSale ? 'للبيع' : 'للإيجار'}  •  ${widget.ad.deliveryService ? 'يوجد توصيل' : 'بدون توصيل'}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Text('خريطة: ${widget.ad.location!.coordinates.join(', ')}'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final coords = widget.ad.location!.coordinates;
                                    // assume coords = [lat, lng]
                                    final lat = coords.isNotEmpty ? coords[0] : 0.0;
                                    final lng = coords.length > 1 ? coords[1] : 0.0;
                                    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الخرائط')));
                                    }
                                  },
                                  icon: const Icon(Icons.map),
                                  label: const Text('فتح في الخرائط'),
                                ),
                              ],
                            )
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
