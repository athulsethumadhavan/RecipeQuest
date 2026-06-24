import 'dart:convert';

class DishIngredient {
  final String name;
  final String measure;

  const DishIngredient({required this.name, required this.measure});

  factory DishIngredient.fromMap(Map<String, dynamic> map) {
    return DishIngredient(
      name: map['name'] as String,
      measure: map['measure'] as String,
    );
  }
}

class DishDetail {
  final int id;
  final int dishId;
  final String dishName;
  final String thumbnailUrl;
  final String cuisineName;
  final String category;
  final String shortDescription;
  final String fullDescription;
  final List<DishIngredient> ingredients;
  final String preparation; // raw text, newline-separated steps
  final String? videoUrl;

  const DishDetail({
    required this.id,
    required this.dishId,
    required this.dishName,
    required this.thumbnailUrl,
    required this.cuisineName,
    required this.category,
    required this.shortDescription,
    required this.fullDescription,
    required this.ingredients,
    required this.preparation,
    this.videoUrl,
  });

  factory DishDetail.fromMap(Map<String, dynamic> map) {
    final rawIngredients =
        jsonDecode(map['ingredients'] as String) as List<dynamic>;
    return DishDetail(
      id: map['detail_id'] as int,
      dishId: map['dish_id'] as int,
      dishName: map['name'] as String,
      thumbnailUrl: map['thumbnail_url'] as String,
      cuisineName: map['cuisine_name'] as String? ?? '',
      category: map['category'] as String,
      shortDescription: map['short_description'] as String,
      fullDescription: map['full_description'] as String,
      ingredients: rawIngredients
          .map((e) => DishIngredient.fromMap(e as Map<String, dynamic>))
          .toList(),
      preparation: map['preparation'] as String,
      videoUrl: map['video_url'] as String?,
    );
  }

  List<String> get preparationSteps => preparation
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
