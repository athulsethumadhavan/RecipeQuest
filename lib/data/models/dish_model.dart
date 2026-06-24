class Dish {
  final int id;
  final int cuisineId;
  final String name;
  final String thumbnailUrl;
  final String category;
  final String shortDescription;
  final String cuisineName; // joined from cuisines table

  const Dish({
    required this.id,
    required this.cuisineId,
    required this.name,
    required this.thumbnailUrl,
    required this.category,
    required this.shortDescription,
    required this.cuisineName,
  });

  factory Dish.fromMap(Map<String, dynamic> map) {
    return Dish(
      id: map['id'] as int,
      cuisineId: map['cuisine_id'] as int,
      name: map['name'] as String,
      thumbnailUrl: map['thumbnail_url'] as String,
      category: map['category'] as String,
      shortDescription: map['short_description'] as String,
      cuisineName: map['cuisine_name'] as String? ?? '',
    );
  }
}
