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
  /// Used by the language picker — keys are display names, values are URLs.
  Map<String, String> get availableVideoUrls {
    final map = <String, String>{};
    if (videoUrlEn?.isNotEmpty == true) map['English']    = videoUrlEn!;
    if (videoUrlHi?.isNotEmpty == true) map['Hindi']      = videoUrlHi!;
    if (videoUrlTa?.isNotEmpty == true) map['Tamil']      = videoUrlTa!;
    if (videoUrlMl?.isNotEmpty == true) map['Malayalam']  = videoUrlMl!;
    if (videoUrlAr?.isNotEmpty == true) map['Arabic']     = videoUrlAr!;
    if (videoUrlDe?.isNotEmpty == true) map['German']     = videoUrlDe!;
    if (videoUrlFr?.isNotEmpty == true) map['French']     = videoUrlFr!;
    if (videoUrlEs?.isNotEmpty == true) map['Spanish']    = videoUrlEs!;
    if (videoUrlIt?.isNotEmpty == true) map['Italian']    = videoUrlIt!;
    if (videoUrlZh?.isNotEmpty == true) map['Chinese']    = videoUrlZh!;
    return map;
  }

  bool get hasVideo => availableVideoUrls.isNotEmpty;

  factory DishDetail.fromMap(Map<String, dynamic> map) {
    final rawIngredients =
        jsonDecode(map['ingredients'] as String) as List<dynamic>;
    final raw = (map['categories_raw'] as String?) ?? '';
    return DishDetail(
      id: map['detail_id'] as int,
      dishId: map['dish_id'] as int,
      dishName: map['name'] as String,
      thumbnailUrl: map['thumbnail_url'] as String,
      cuisineName: map['cuisine_name'] as String? ?? '',
      categories: raw.isEmpty
          ? []
          : raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      shortDescription: map['short_description'] as String,
      fullDescription: map['full_description'] as String,
      ingredients: rawIngredients.map((e) {
        if (e is Map<String, dynamic>) {
          // Legacy format: {"name": "...", "measure": "..."}
          return DishIngredient.fromMap(e);
        } else {
          // New format: plain string e.g. "400g spaghetti"
          return DishIngredient(name: e as String, measure: '');
        }
      }).toList(),
      preparation: map['preparation'] as String,
      videoUrlEn: map['video_url_en'] as String?,
      videoUrlHi: map['video_url_hi'] as String?,
      videoUrlTa: map['video_url_ta'] as String?,
      videoUrlMl: map['video_url_ml'] as String?,
      videoUrlAr: map['video_url_ar'] as String?,
      videoUrlDe: map['video_url_de'] as String?,
      videoUrlFr: map['video_url_fr'] as String?,
      videoUrlEs: map['video_url_es'] as String?,
      videoUrlIt: map['video_url_it'] as String?,
      videoUrlZh: map['video_url_zh'] as String?,
    );
  }

  List<String> get preparationSteps => preparation
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
