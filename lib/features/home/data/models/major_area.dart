class MajorArea {
  final int id;
  final String name;
  final int provinceId;

  MajorArea({
    required this.id,
    required this.name,
    required this.provinceId,
  });

  factory MajorArea.fromJson(Map<String, dynamic> json) {
    return MajorArea(
      id: json['id'] as int,
      name: json['name'] as String,
      provinceId: (json['ProvinceId'] ?? json['provinceId'] ?? json['province_id']) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ProvinceId': provinceId,
    };
  }
}
