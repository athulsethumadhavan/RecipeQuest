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
import 'data/repositories/cuisine_repository.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/preference_repository.dart';
import 'presentation/viewmodels/home_viewmodel.dart';
import 'presentation/viewmodels/detail_viewmodel.dart';
import 'presentation/viewmodels/search_viewmodel.dart';
import 'presentation/viewmodels/cuisine_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase client.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Open local SQLite (runs migrations if needed).
  await AppDatabase.database;

  // Sync remote data into local DB; UI always reads from SQLite.
  // On error (e.g. no network) the app continues with whatever is cached locally.
  try {
    await SyncService.sync();
  } catch (e, st) {
    debugPrint('[SyncService] error: $e\n$st');
  }

  await MobileAds.instance.initialize();
  AdService.loadRewardedAd(); // pre-load first ad

  // Init IAP — creates the product reference used by the paywall
  final prefRepo = PreferenceRepository();
  await PaymentService.init(prefRepo);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(RecipeQuestApp(prefRepository: prefRepo));
}

class RecipeQuestApp extends StatelessWidget {
  final PreferenceRepository prefRepository;
  const RecipeQuestApp({super.key, required this.prefRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CuisineRepository>(create: (_) => CuisineRepository()),
        ChangeNotifierProvider<FavoritesRepository>(
            create: (_) => FavoritesRepository()),
        ChangeNotifierProvider<PreferenceRepository>.value(
          value: prefRepository,
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (ctx) => HomeViewModel(
            repository: ctx.read<CuisineRepository>(),
            prefRepository: ctx.read<PreferenceRepository>(),
          ),
        ),
        ChangeNotifierProvider<DetailViewModel>(
          create: (ctx) => DetailViewModel(
            repository: ctx.read<CuisineRepository>(),
            favoritesRepository: ctx.read<FavoritesRepository>(),
          ),
        ),
        ChangeNotifierProvider<SearchViewModel>(
          create: (ctx) => SearchViewModel(
            repository: ctx.read<CuisineRepository>(),
          ),
        ),
        ChangeNotifierProvider<CuisineViewModel>(
          create: (ctx) => CuisineViewModel(
            repository: ctx.read<CuisineRepository>(),
          ),
        ),
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
