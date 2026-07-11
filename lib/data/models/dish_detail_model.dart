import 'dart:convert';

class DishIngredient {
  final String name;
  final String measure;

  const DishIngredient({required this.name, required this.measure});

  factory DishIngredient.fromMap(Map<String, dynamic> map) {
    return DishIngredient(
      name: (map['name'] as String?) ?? '',
      measure: (map['measure'] as String?) ?? '',
    );
  }
}

class DishDetail {
  final int id;
  final int dishId;
  final int cuisineId;
  final String dishName;
  final String thumbnailUrl;
  final String cuisineName;
  final List<String> categories;
  final String shortDescription;
  final String fullDescription;
  final List<DishIngredient> ingredients;
  final String preparation;

  // Per-language video URLs
  final String? videoUrlEn;
  final String? videoUrlHi;
  final String? videoUrlTa;
  final String? videoUrlMl;
  final String? videoUrlAr;
  final String? videoUrlDe;
  final String? videoUrlFr;
  final String? videoUrlEs;
  final String? videoUrlIt;
  final String? videoUrlZh;

  const DishDetail({
    required this.id,
    required this.dishId,
    required this.cuisineId,
    required this.dishName,
    required this.thumbnailUrl,
    required this.cuisineName,
    required this.categories,
    required this.shortDescription,
    required this.fullDescription,
    required this.ingredients,
    required this.preparation,
    this.videoUrlEn,
    this.videoUrlHi,
    this.videoUrlTa,
    this.videoUrlMl,
    this.videoUrlAr,
    this.videoUrlDe,
    this.videoUrlFr,
    this.videoUrlEs,
    this.videoUrlIt,
    this.videoUrlZh,
  });

  /// First category for compact display (e.g. chip on detail screen).
  String get primaryCategory => categories.isNotEmpty ? categories.first : '';

  /// Returns only languages that have a non-empty URL.
  Map<String, String> get availableVideoUrls {
    final map = <String, String>{};
    if (videoUrlEn?.isNotEmpty == true) map['English']   = videoUrlEn!;
    if (videoUrlHi?.isNotEmpty == true) map['Hindi']     = videoUrlHi!;
    if (videoUrlTa?.isNotEmpty == true) map['Tamil']     = videoUrlTa!;
    if (videoUrlMl?.isNotEmpty == true) map['Malayalam'] = videoUrlMl!;
    if (videoUrlAr?.isNotEmpty == true) map['Arabic']    = videoUrlAr!;
    if (videoUrlDe?.isNotEmpty == true) map['German']    = videoUrlDe!;
    if (videoUrlFr?.isNotEmpty == true) map['French']    = videoUrlFr!;
    if (videoUrlEs?.isNotEmpty == true) map['Spanish']   = videoUrlEs!;
    if (videoUrlIt?.isNotEmpty == true) map['Italian']   = videoUrlIt!;
    if (videoUrlZh?.isNotEmpty == true) map['Chinese']   = videoUrlZh!;
    return map;
  }

  bool get hasVideo => availableVideoUrls.isNotEmpty;

  List<String> get preparationSteps => preparation
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// Deserialise from a Supabase response with embedded `dishes` relation
  /// that itself embeds `cuisines(name)` and `dish_categories(categories(name))`.
  factory DishDetail.fromSupabase(Map<String, dynamic> map) {
    final dishData       = map['dishes'] as Map<String, dynamic>? ?? {};
    final cuisineData    = dishData['cuisines'] as Map<String, dynamic>?;
    final dishCategories = dishData['dish_categories'] as List<dynamic>? ?? [];

    final categories = dishCategories
        .map((dc) {
          final catData = dc['categories'] as Map<String, dynamic>?;
          return (catData?['name'] as String?) ?? '';
        })
        .where((n) => n.isNotEmpty)
        .toList();

    final rawIngredients = _parseIngredients(map['ingredients']);

    return DishDetail(
      id:               map['id'] as int,
      dishId:           map['dish_id'] as int,
      cuisineId:        (dishData['cuisine_id'] as int?) ?? 0,
      dishName:         (dishData['name'] as String?) ?? '',
      thumbnailUrl:     (dishData['thumbnail_url'] as String?) ?? '',
      cuisineName:      (cuisineData?['name'] as String?) ?? '',
      categories:       categories,
      shortDescription: (dishData['short_description'] as String?) ?? '',
      fullDescription:  (map['full_description'] as String?) ?? '',
      ingredients: rawIngredients.map((e) {
        if (e is Map<String, dynamic>) return DishIngredient.fromMap(e);
        return DishIngredient(name: e.toString(), measure: '');
      }).toList(),
      preparation:  (map['preparation'] as String?) ?? '',
      videoUrlEn:   map['video_url_en'] as String?,
      videoUrlHi:   map['video_url_hi'] as String?,
      videoUrlTa:   map['video_url_ta'] as String?,
      videoUrlMl:   map['video_url_ml'] as String?,
      videoUrlAr:   map['video_url_ar'] as String?,
      videoUrlDe:   map['video_url_de'] as String?,
      videoUrlFr:   map['video_url_fr'] as String?,
      videoUrlEs:   map['video_url_es'] as String?,
      videoUrlIt:   map['video_url_it'] as String?,
      videoUrlZh:   map['video_url_zh'] as String?,
    );
  }

  /// Safely parse the `ingredients` field which may arrive as a JSONB List
  /// (direct from Supabase) or a JSON String (legacy).
  static List<dynamic> _parseIngredients(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }
}
