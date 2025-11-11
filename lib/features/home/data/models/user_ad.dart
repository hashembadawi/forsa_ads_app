class UserAd {
  final String id;
  final String adTitle;
  final String thumbnail;
  final double price;
  final String currencyName;
  final String categoryName;
  final DateTime createDate;
  final String cityName;
  final String? regionName;
  final bool isApproved;
  final String description;
  final bool forSale;
  final bool deliveryService;
  final bool isSpecial;
  final List<Map<String, dynamic>> images;

  UserAd({
    required this.id,
    required this.adTitle,
    required this.thumbnail,
    required this.price,
    required this.currencyName,
    required this.categoryName,
    required this.createDate,
    required this.cityName,
    this.regionName,
    required this.isApproved,
    this.description = '',
    this.forSale = true,
    this.deliveryService = false,
    this.isSpecial = false,
    this.images = const [],
  });

  factory UserAd.fromJson(Map<String, dynamic> json) {
    return UserAd(
      id: json['_id'] ?? '',
      adTitle: json['adTitle'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currencyName: json['currencyName'] ?? '',
      categoryName: json['categoryName'] ?? '',
      createDate: json['createDate'] != null
          ? DateTime.parse(json['createDate'])
          : DateTime.now(),
      cityName: json['cityName'] ?? '',
      regionName: json['regionName'],
      isApproved: json['isApproved'] ?? false,
      description: json['description'] ?? '',
      forSale: json['forSale'] ?? true,
      deliveryService: json['deliveryService'] ?? false,
      isSpecial: json['isSpecial'] ?? false,
      images: (json['images'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
