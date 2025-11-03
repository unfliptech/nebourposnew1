class MetaModel {
  const MetaModel({
    required this.themeHash,
    required this.menuHash,
    required this.updatedAt,
  });

  final String themeHash;
  final String menuHash;
  final DateTime updatedAt;

  factory MetaModel.fromJson(Map<String, dynamic> json) {
    return MetaModel(
      themeHash: json['theme_hash'] as String,
      menuHash: json['menu_hash'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_hash': themeHash,
      'menu_hash': menuHash,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
