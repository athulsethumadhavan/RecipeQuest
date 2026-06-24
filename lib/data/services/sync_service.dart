import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';

class SyncResult {
  final bool success;
  final String? error;
  final int cuisinesFetched;
  final int dishesFetched;
  final int detailsFetched;

  const SyncResult({
    required this.success,
    this.error,
    this.cuisinesFetched = 0,
    this.dishesFetched = 0,
    this.detailsFetched = 0,
  });
}

/// Pulls cuisines, dishes, and dish_details from Supabase and
/// upserts them into the local SQLite database.
/// Called once on app launch; app always reads from local SQLite.
class SyncService {
  SyncService._();

  static SyncResult? lastResult;

  static Future<void> sync() async {
    lastResult = await syncWithResult();
  }

  static Future<SyncResult> syncWithResult() async {
    try {
      final client = Supabase.instance.client;
      final db = await AppDatabase.database;

      // ── Cuisines ──────────────────────────────────────────────────────────
      final cuisinesRaw = await client
          .from('cuisines')
          .select()
          .order('id') as List<dynamic>;

      if (cuisinesRaw.isNotEmpty) {
        final cuisineRows = cuisinesRaw
            .map((r) => _sanitizeCuisine(r as Map<String, dynamic>))
            .toList();
        final cuisineIds = cuisineRows.map((r) => r['id'] as int).toList();

        await db.transaction((txn) async {
          final ph = List.filled(cuisineIds.length, '?').join(',');
          await txn.rawDelete(
            'DELETE FROM cuisines WHERE id NOT IN ($ph)',
            cuisineIds,
          );
          for (final row in cuisineRows) {
            await txn.insert(
              'cuisines',
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      }

      // ── Dishes ────────────────────────────────────────────────────────────
      final dishesRaw = await client
          .from('dishes')
          .select()
          .order('id') as List<dynamic>;

      if (dishesRaw.isNotEmpty) {
        final dishRows = dishesRaw
            .map((r) => _sanitizeDish(r as Map<String, dynamic>))
            .toList();
        final dishIds = dishRows.map((r) => r['id'] as int).toList();

        await db.transaction((txn) async {
          final ph = List.filled(dishIds.length, '?').join(',');
          await txn.rawDelete(
            'DELETE FROM dishes WHERE id NOT IN ($ph)',
            dishIds,
          );
          for (final row in dishRows) {
            await txn.insert(
              'dishes',
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      }

      // ── Dish details ──────────────────────────────────────────────────────
      final detailsRaw = await client
          .from('dish_details')
          .select()
          .order('id') as List<dynamic>;

      if (detailsRaw.isNotEmpty) {
        final detailRows = detailsRaw
            .map((r) => _sanitizeDetail(r as Map<String, dynamic>))
            .toList();
        final detailIds = detailRows.map((r) => r['id'] as int).toList();

        await db.transaction((txn) async {
          final ph = List.filled(detailIds.length, '?').join(',');
          await txn.rawDelete(
            'DELETE FROM dish_details WHERE id NOT IN ($ph)',
            detailIds,
          );
          for (final row in detailRows) {
            await txn.insert(
              'dish_details',
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      }

      return SyncResult(
        success: true,
        cuisinesFetched: cuisinesRaw.length,
        dishesFetched: dishesRaw.length,
        detailsFetched: detailsRaw.length,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  static Map<String, dynamic> _sanitizeCuisine(Map<String, dynamic> r) => {
        'id': (r['id'] as num).toInt(),
        'name': r['name'] ?? '',
        'flag': r['flag'] ?? '',
        'description': r['description'] ?? '',
        'gradient_start':
            (r['gradient_start'] ?? '4A90E2').toString().replaceAll('#', ''),
        'gradient_end':
            (r['gradient_end'] ?? '2F74CC').toString().replaceAll('#', ''),
        'thumbnail_url': r['thumbnail_url'] ?? '',
        'categories': r['categories'] ?? '',
      };

  static Map<String, dynamic> _sanitizeDish(Map<String, dynamic> r) => {
        'id': (r['id'] as num).toInt(),
        'cuisine_id': (r['cuisine_id'] as num).toInt(),
        'name': r['name'] ?? '',
        'thumbnail_url': r['thumbnail_url'] ?? '',
        'category': r['category'] ?? '',
        'short_description': r['short_description'] ?? '',
      };

  static Map<String, dynamic> _sanitizeDetail(Map<String, dynamic> r) => {
        'id': (r['id'] as num).toInt(),
        'dish_id': (r['dish_id'] as num).toInt(),
        'full_description': r['full_description'] ?? '',
        'ingredients': r['ingredients'] is String
            ? r['ingredients']
            : (r['ingredients'] ?? '').toString(),
        'preparation': r['preparation'] ?? '',
        'video_url': r['video_url'],
      };
}
