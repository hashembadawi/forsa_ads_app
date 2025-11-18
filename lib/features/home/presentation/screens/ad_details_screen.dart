import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('تعذر فتح الخرائط')));
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
