import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/services/sync_service.dart';
import 'data/services/ad_service.dart';
import 'data/services/payment_service.dart';
import 'data/services/realtime_sync_service.dart';
import 'data/repositories/cuisine_repository.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/preference_repository.dart';
import 'presentation/viewmodels/home_viewmodel.dart';
import 'presentation/viewmodels/detail_viewmodel.dart';
import 'presentation/viewmodels/search_viewmodel.dart';
import 'presentation/viewmodels/cuisine_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await AppDatabase.database;

  try {
    await SyncService.sync();
  } catch (e, st) {
    debugPrint('[SyncService] error: $e\n$st');
  }

  await MobileAds.instance.initialize();
  AdService.loadRewardedAd();

  await PaymentService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const RecipeQuestApp());
}

class RecipeQuestApp extends StatefulWidget {
  const RecipeQuestApp({super.key});

  @override
  State<RecipeQuestApp> createState() => _RecipeQuestAppState();
}

class _RecipeQuestAppState extends State<RecipeQuestApp> {
  // Shared repository instances — one of each, reused by all ViewModels.
  final _cuisineRepo  = CuisineRepository();
  final _prefRepo     = PreferenceRepository();
  final _favRepo      = FavoritesRepository();

  late final HomeViewModel     _homeVM;
  late final SearchViewModel   _searchVM;
  late final CuisineViewModel  _cuisineVM;
  late final DetailViewModel   _detailVM;

  @override
  void initState() {
    super.initState();

    _homeVM    = HomeViewModel(repository: _cuisineRepo, prefRepository: _prefRepo);
    _searchVM  = SearchViewModel(repository: _cuisineRepo);
    _cuisineVM = CuisineViewModel(repository: _cuisineRepo);
    _detailVM  = DetailViewModel(repository: _cuisineRepo, favoritesRepository: _favRepo);

    // Subscribe to Supabase Realtime — re-syncs SQLite on any table change.
    RealtimeSyncService.start(onSynced: _onRemoteDataChanged);
  }

  /// Called on the main thread after every successful Realtime-triggered sync.
  void _onRemoteDataChanged() {
    _homeVM.refresh();
    _searchVM.refresh();
    _cuisineVM.refresh();
  }

  @override
  void dispose() {
    RealtimeSyncService.stop();
    _homeVM.dispose();
    _searchVM.dispose();
    _cuisineVM.dispose();
    _detailVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CuisineRepository>.value(value: _cuisineRepo),
        ChangeNotifierProvider<FavoritesRepository>.value(value: _favRepo),
        ChangeNotifierProvider<PreferenceRepository>.value(value: _prefRepo),
        ChangeNotifierProvider<HomeViewModel>.value(value: _homeVM),
        ChangeNotifierProvider<DetailViewModel>.value(value: _detailVM),
        ChangeNotifierProvider<SearchViewModel>.value(value: _searchVM),
        ChangeNotifierProvider<CuisineViewModel>.value(value: _cuisineVM),
      ],
      child: MaterialApp.router(
        title: 'Recipe Quest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
