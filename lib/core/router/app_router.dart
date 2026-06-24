import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/dish_model.dart';
import '../../presentation/views/splash/splash_screen.dart';
import '../../presentation/views/home/home_screen.dart';
import '../../presentation/views/search/search_screen.dart';
import '../../presentation/views/detail/detail_screen.dart';
import '../../presentation/views/cuisine/cuisine_list_screen.dart';
import '../../presentation/views/cuisine/cuisine_meals_screen.dart';
import '../../presentation/views/admin/admin_screen.dart';
import '../../presentation/views/onboarding/cuisine_preference_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String home = '/home';
  static const String search = '/search';
  static const String cuisines = '/cuisines';
  static const String cuisineMeals = '/cuisines/:id';
  static const String detail = '/detail/:id';
  static const String admin = '/admin';
  static const String onboarding = '/onboarding';
  static const String cuisinePreference = '/preference';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      // Screens without banner ad
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
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
          return DetailScreen(dishId: id, preloadedDish: dish);
        },
      ),

      // All other main screens — wrapped with banner ad at bottom
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
            path: cuisines,
            builder: (context, state) => const CuisineListScreen(),
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
          GoRoute(
            path: cuisinePreference,
            builder: (context, state) =>
                const CuisinePreferenceScreen(isEditing: true),
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
