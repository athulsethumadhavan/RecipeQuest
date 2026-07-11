import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/ad_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/payment_service.dart';
import 'data/repositories/cuisine_repository.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/preference_repository.dart';
import 'presentation/viewmodels/home_viewmodel.dart';
import 'presentation/viewmodels/search_viewmodel.dart';
import 'presentation/viewmodels/cuisine_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Suppress noisy WebView logs from youtube_player_flutter
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null &&
        (message.contains('VideoTime') ||
         message.contains('calling "Video') ||
         message.contains('WebView ID'))) {
      return;
    }
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

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

  @override
  void initState() {
    super.initState();

    _homeVM    = HomeViewModel(repository: _cuisineRepo, prefRepository: _prefRepo, authService: AuthService.instance);
    _searchVM  = SearchViewModel(repository: _cuisineRepo);
    _cuisineVM = CuisineViewModel(repository: _cuisineRepo);

    _favRepo.ensureLoaded();
  }

  @override
  void dispose() {
    _homeVM.dispose();
    _searchVM.dispose();
    _cuisineVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CuisineRepository>.value(value: _cuisineRepo),
        ChangeNotifierProvider<AuthService>.value(value: AuthService.instance),
        ChangeNotifierProvider<FavoritesRepository>.value(value: _favRepo),
        ChangeNotifierProvider<PreferenceRepository>.value(value: _prefRepo),
        ChangeNotifierProvider<HomeViewModel>.value(value: _homeVM),
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
