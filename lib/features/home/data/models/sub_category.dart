class SubCategory {
  final int id;
  final String name;
  final int categoryId;

  SubCategory({
    required this.id,
    required this.name,
    required this.categoryId,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: (json['name'] ?? json['subCategoryName'] ?? json['title'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? json['CategoryId'] ?? json['category_id']) is int
          ? (json['categoryId'] ?? json['CategoryId'] ?? json['category_id']) as int
          : int.tryParse((json['categoryId'] ?? json['CategoryId'] ?? json['category_id']).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
    };
  }
}
