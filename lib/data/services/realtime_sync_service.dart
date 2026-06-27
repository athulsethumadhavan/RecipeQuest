import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_service.dart';

/// Subscribes to Supabase Realtime on every data table.
/// When any row is inserted / updated / deleted the local SQLite cache is
/// refreshed automatically — no app update required.
///
/// Usage:
///   await RealtimeSyncService.start(onSynced: () { /* notify UI */ });
///   // ... later on app dispose:
///   await RealtimeSyncService.stop();
class RealtimeSyncService {
  RealtimeSyncService._();

  static final SupabaseClient _sb = Supabase.instance.client;

  static RealtimeChannel? _channel;

  /// [onSynced] is called on the main isolate after every successful sync.
  static Future<void> start({VoidCallback? onSynced}) async {
    await stop(); // cancel any previous subscription

    _channel = _sb
        .channel('db-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'cuisines',
          callback: (_) => _handleChange(onSynced),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dishes',
          callback: (_) => _handleChange(onSynced),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dish_details',
          callback: (_) => _handleChange(onSynced),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'categories',
          callback: (_) => _handleChange(onSynced),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'cuisine_categories',
          callback: (_) => _handleChange(onSynced),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dish_categories',
          callback: (_) => _handleChange(onSynced),
        )
        .subscribe((status, [error]) {
          debugPrint('[RealtimeSyncService] status=$status error=$error');
        });
  }

  static Future<void> stop() async {
    if (_channel != null) {
      await _sb.removeChannel(_channel!);
      _channel = null;
    }
  }

  // Debounce rapid bursts (e.g. bulk INSERT fires one event per row).
  static bool _syncing = false;

  static Future<void> _handleChange(VoidCallback? onSynced) async {
    if (_syncing) return; // already in progress — skip duplicate
    _syncing = true;
    debugPrint('[RealtimeSyncService] change detected — syncing…');
    try {
      await SyncService.sync();
      debugPrint('[RealtimeSyncService] sync complete');
      onSynced?.call();
    } catch (e) {
      debugPrint('[RealtimeSyncService] sync error: $e');
    } finally {
      _syncing = false;
    }
  }
}
