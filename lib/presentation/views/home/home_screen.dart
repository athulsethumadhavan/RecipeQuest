import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../data/models/cuisine_model.dart';
import '../../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _titleTapCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
    });
  }

  void _onTitleDoubleTap() {
    _titleTapCount++;
    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      context.push(AppRouter.admin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const SafeArea(
        child: BannerAdWidget(),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onDoubleTap: _onTitleDoubleTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, Foodie! 👋',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What do you want\ncooking today?',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _IconBtn(
                        icon: Icons.search_rounded,
                        onTap: () => context.push(AppRouter.search),
                      ),
                      const SizedBox(width: 10),
                      _IconBtn(
                        icon: Icons.favorite_border_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Section label ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Popular Cuisine',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),

            const SizedBox(height: 16),

            // ── Cuisine list ──────────────────────────────────────────────
            Expanded(
              child: Consumer<HomeViewModel>(
                builder: (context, vm, _) {
                  if (vm.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (vm.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('😕', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(vm.errorMessage ?? 'Something went wrong'),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: vm.refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: vm.refresh,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      // +1 for the "Explore More" card
                      itemCount: vm.cuisines.length + 1,
                      itemBuilder: (context, i) {
                        if (i == vm.cuisines.length) {
                          return _ExploreMoreCard(
                            onTap: () async {
                              await context.push(AppRouter.cuisinePreference);
                              vm.refresh();
                            },
                          );
                        }
                        return _CuisineCard(
                          cuisine: vm.cuisines[i],
                          onTap: () => context.push(
                            AppRouter.cuisineMeals
                                .replaceFirst(':id', '${vm.cuisines[i].id}'),
                            extra: vm.cuisines[i],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cuisine card ──────────────────────────────────────────────────────────────

class _CuisineCard extends StatelessWidget {
  final Cuisine cuisine;
  final VoidCallback onTap;

  const _CuisineCard({required this.cuisine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: cuisine.startColor.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Dish image
              CachedNetworkImage(
                imageUrl: cuisine.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: cuisine.startColor.withOpacity(0.4)),
                errorWidget: (_, __, ___) =>
                    Container(color: cuisine.startColor.withOpacity(0.4)),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              // Text at bottom
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cuisine.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Explore',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white.withOpacity(0.85), size: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Explore more card ─────────────────────────────────────────────────────────

class _ExploreMoreCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ExploreMoreCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Explore\nMore',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add cuisines',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}
