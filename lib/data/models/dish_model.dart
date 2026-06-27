class Dish {
  final int id;
  final int cuisineId;
  final String name;
  final String thumbnailUrl;
  final List<String> categories;
  final String shortDescription;
  final String cuisineName; // joined from cuisines table

  const Dish({
    required this.id,
    required this.cuisineId,
    required this.name,
    required this.thumbnailUrl,
    required this.categories,
    required this.shortDescription,
    required this.cuisineName,
  });

  /// First category for compact display (e.g. card chip).
  String get primaryCategory => categories.isNotEmpty ? categories.first : '';

  factory Dish.fromMap(Map<String, dynamic> map) {
    final raw = (map['categories_raw'] as String?) ?? '';
    return Dish(
      id: map['id'] as int,
      cuisineId: map['cuisine_id'] as int,
      name: map['name'] as String,
      thumbnailUrl: map['thumbnail_url'] as String,
      categories: raw.isEmpty
          ? []
          : raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      shortDescription: map['short_description'] as String,
      cuisineName: map['cuisine_name'] as String? ?? '',
    );
  }
}
