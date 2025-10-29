class CurrencyOption {
  final int id;
  final String name;

  CurrencyOption({required this.id, required this.name});

  factory CurrencyOption.fromJson(Map<String, dynamic> json) {
    return CurrencyOption(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: (json['name'] ?? json['code'] ?? json['Code'] ?? json['currency'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
