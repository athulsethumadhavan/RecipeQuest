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

  /// Deserialise from SharedPreferences (flat map with `categories_raw` string).
  factory Dish.fromMap(Map<String, dynamic> map) {
    final raw = (map['categories_raw'] as String?) ?? '';
    return Dish(
      id: map['id'] as int,
      cuisineId: map['cuisine_id'] as int,
      name: (map['name'] as String?) ?? '',
      thumbnailUrl: (map['thumbnail_url'] as String?) ?? '',
      categories: raw.isEmpty
          ? []
          : raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      shortDescription: (map['short_description'] as String?) ?? '',
      cuisineName: (map['cuisine_name'] as String?) ?? '',
    );
  }

  /// Deserialise from a Supabase response with embedded `cuisines` and
  /// `dish_categories(categories(name))` relations.
  factory Dish.fromSupabase(Map<String, dynamic> map) {
    final cuisineData = map['cuisines'] as Map<String, dynamic>?;
    final dishCategories = map['dish_categories'] as List<dynamic>? ?? [];
    final categories = dishCategories
        .map((dc) {
          final catData = dc['categories'] as Map<String, dynamic>?;
          return (catData?['name'] as String?) ?? '';
        })
        .where((n) => n.isNotEmpty)
        .toList();

    return Dish(
      id: map['id'] as int,
      cuisineId: (map['cuisine_id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? '',
      thumbnailUrl: (map['thumbnail_url'] as String?) ?? '',
      categories: categories,
      shortDescription: (map['short_description'] as String?) ?? '',
      cuisineName: (cuisineData?['name'] as String?) ?? '',
    );
  }
}
