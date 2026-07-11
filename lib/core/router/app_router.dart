import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/dish_model.dart';
import '../../presentation/viewmodels/detail_viewmodel.dart';
import '../../presentation/views/splash/splash_screen.dart';
import '../../presentation/views/home/home_screen.dart';
import '../../presentation/views/search/search_screen.dart';
import '../../presentation/views/detail/detail_screen.dart';
import '../../presentation/views/cuisine/cuisine_list_screen.dart';
import '../../presentation/views/cuisine/cuisine_meals_screen.dart';
import '../../presentation/views/admin/admin_screen.dart';
import '../../presentation/views/onboarding/cuisine_preference_screen.dart';
import '../../presentation/views/auth/auth_screen.dart';
import '../../presentation/views/auth/register_screen.dart';
import '../../presentation/views/onboarding/onboarding_intro_screen.dart';
import '../../presentation/views/favorites/favorites_screen.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String intro = '/intro';
  static const String auth = '/auth';
  static const String register = '/register';
  static const String home = '/home';
  static const String search = '/search';
  static const String cuisines = '/cuisines';
  static const String cuisineMeals = '/cuisines/:id';
  static const String detail = '/detail/:id';
  static const String admin = '/admin';
  static const String onboarding = '/onboarding';
  static const String cuisinePreference = '/preference';
  static const String favorites = '/favorites';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    observers: [AnalyticsService.instance.observer],
    // Redirect to /auth if the user tries to access protected pages while signed out
    redirect: (context, state) {
      final isLoggedIn = AuthService.instance.isLoggedIn;
      final path = state.matchedLocation;
      final publicPaths = [splash, intro, auth, register];
      if (!isLoggedIn && !publicPaths.contains(path)) {
        return auth;
      }
      return null;
    },
    routes: [
      // Screens without banner ad
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: intro,
        builder: (context, state) => const OnboardingIntroScreen(),
      ),
      GoRoute(
        path: auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const CuisinePreferenceScreen(),
      ),
      GoRoute(
        path: detail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final dish = state.extra as Dish?;
          return ChangeNotifierProvider(
            create: (_) => DetailViewModel(),
            child: DetailScreen(dishId: id, preloadedDish: dish),
          );
        },
      ),
      GoRoute(
        path: cuisines,
        builder: (context, state) => const CuisineListScreen(),
      ),
      // Explore More — no banner ad
      GoRoute(
        path: cuisinePreference,
        builder: (context, state) =>
            const CuisinePreferenceScreen(isEditing: true),
      ),

      // Favourites — no banner ad
      GoRoute(
        path: favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),

      // Main screens — wrapped with banner ad at bottom
      ShellRoute(
        builder: (context, state, child) => _AdShell(child: child),
        routes: [
          GoRoute(
            path: home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: cuisineMeals,
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CuisineMealsScreen(cuisineId: id);
            },
          ),
          GoRoute(
            path: admin,
            builder: (context, state) => const AdminScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

/// Shell that places a persistent banner ad below every main screen.
class _AdShell extends StatelessWidget {
  final Widget child;
  const _AdShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const SafeArea(
        child: BannerAdWidget(),
      ),
    );
  }
}
