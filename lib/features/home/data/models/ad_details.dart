import 'dart:convert';

class LocationPoint {
  final String type;
  final List<double> coordinates;

  LocationPoint({required this.type, required this.coordinates});

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    final coords = <double>[];
    try {
      final raw = json['coordinates'];
      if (raw is List) {
        for (final c in raw) {
          final d = c is num ? c.toDouble() : double.tryParse(c.toString());
          if (d != null) coords.add(d);
        }
      }
    } catch (_) {}
    return LocationPoint(type: json['type'] ?? 'Point', coordinates: coords);
  }
}

class AdDetails {
  final LocationPoint? location;
  final String id;
  final String adTitle;
  final String userId;
  final String userName;
  final String userPhone;
  final List<String> images; // base64 strings or data URIs
  final String thumbnail; // base64 string
  final double price;
  final int? currencyId;
  final String currencyName;
  final int? categoryId;
  final String categoryName;
  final int? subCategoryId;
  final String subCategoryName;
  final int? cityId;
  final String cityName;
  final int? regionId;
  final String? regionName;
  final DateTime createDate;
  final String description;
  final bool isApproved;
  final bool isNew;
  final bool forSale;
  final bool deliveryService;
  final bool isSpecial;
  final int v;

  AdDetails({
    this.location,
    required this.id,
    required this.adTitle,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.images,
    required this.thumbnail,
    required this.price,
    this.currencyId,
    required this.currencyName,
    this.categoryId,
    required this.categoryName,
    this.subCategoryId,
    required this.subCategoryName,
    this.cityId,
    required this.cityName,
    this.regionId,
    this.regionName,
    required this.createDate,
    required this.description,
    required this.isApproved,
    required this.isNew,
    required this.forSale,
    required this.deliveryService,
    required this.isSpecial,
    required this.v,
  });

  // Normalize images field to List<String>
  static List<String> _parseImages(dynamic raw) {
    final out = <String>[];
    try {
      if (raw == null) return out;
      if (raw is String) {
        final s = raw.trim();
        if (s.isEmpty) return out;
        // try decode JSON string
        try {
          final decoded = jsonDecode(s);
          return _parseImages(decoded);
        } catch (_) {
          out.add(s);
          return out;
        }
      }
      if (raw is List) {
        for (final e in raw) {
          if (e == null) continue;
          if (e is String) {
            out.add(e);
          } else if (e is Map) {
            // maybe {'content': '...'} or other shape
            final content = e['content'] ?? e['value'] ?? e['data'] ?? '';
            if (content is String && content.isNotEmpty) out.add(content);
          } else {
            out.add(e.toString());
          }
        }
      }
    } catch (_) {}
    return out;
  }

  factory AdDetails.fromJson(Map<String, dynamic> json) {
    LocationPoint? loc;
    try {
      if (json['location'] is Map) loc = LocationPoint.fromJson(Map<String, dynamic>.from(json['location'] as Map));
    } catch (_) {}

    return AdDetails(
      location: loc,
      id: json['_id'] ?? json['id'] ?? '',
      adTitle: json['adTitle'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'] ?? '',
      images: _parseImages(json['images']),
      thumbnail: json['thumbnail'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currencyId: json['currencyId'] is num ? (json['currencyId'] as num).toInt() : int.tryParse((json['currencyId'] ?? '').toString()),
      currencyName: json['currencyName'] ?? '',
      categoryId: json['categoryId'] is num ? (json['categoryId'] as num).toInt() : int.tryParse((json['categoryId'] ?? '').toString()),
      categoryName: json['categoryName'] ?? '',
      subCategoryId: json['subCategoryId'] is num ? (json['subCategoryId'] as num).toInt() : int.tryParse((json['subCategoryId'] ?? '').toString()),
      subCategoryName: json['subCategoryName'] ?? '',
      cityId: json['cityId'] is num ? (json['cityId'] as num).toInt() : int.tryParse((json['cityId'] ?? '').toString()),
      cityName: json['cityName'] ?? '',
      regionId: json['regionId'] is num ? (json['regionId'] as num).toInt() : int.tryParse((json['regionId'] ?? '').toString()),
      regionName: json['regionName'],
      createDate: json['createDate'] != null ? DateTime.parse(json['createDate']) : DateTime.now(),
      description: json['description'] ?? '',
      isApproved: json['isApproved'] ?? false,
      isNew: json['isNew'] ?? false,
      forSale: json['forSale'] ?? true,
      deliveryService: json['deliveryService'] ?? false,
      isSpecial: json['isSpecial'] ?? false,
      v: json['__v'] is int ? json['__v'] as int : int.tryParse((json['__v'] ?? '0').toString()) ?? 0,
    );
  }
}
