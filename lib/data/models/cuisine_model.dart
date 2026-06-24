import 'package:flutter/material.dart';

class Cuisine {
  final int id;
  final String name;
  final String flag;
  final String description;
  final String gradientStart; // hex without #
  final String gradientEnd;
  final String thumbnailUrl;

  const Cuisine({
    required this.id,
    required this.name,
    required this.flag,
    required this.description,
    required this.gradientStart,
    required this.gradientEnd,
    required this.thumbnailUrl,
  });

  factory Cuisine.fromMap(Map<String, dynamic> map) {
    return Cuisine(
      id: map['id'] as int,
      name: map['name'] as String,
      flag: map['flag'] as String,
      description: map['description'] as String,
      gradientStart: map['gradient_start'] as String,
      gradientEnd: map['gradient_end'] as String,
      thumbnailUrl: (map['thumbnail_url'] as String?) ?? '',
    );
  }

  Color get startColor => _hexColor(gradientStart);
  Color get endColor => _hexColor(gradientEnd);

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [startColor, endColor],
      );

  static Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
