import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/services/sync_service.dart';
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
  await SyncService.sync();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const RecipeQuestApp());
}

class RecipeQuestApp extends StatelessWidget {
  const RecipeQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CuisineRepository>(create: (_) => CuisineRepository()),
        Provider<FavoritesRepository>(create: (_) => FavoritesRepository()),

        // Shared singleton — notifies HomeViewModel when preferences change
        ChangeNotifierProvider<PreferenceRepository>(
          create: (_) => PreferenceRepository(),
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
