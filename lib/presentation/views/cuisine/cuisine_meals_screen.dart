import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/dish_model.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../viewmodels/cuisine_viewmodel.dart';

const _cardColors = [
  Color(0xFFFFF3E0),
  Color(0xFFE8F5E9),
  Color(0xFFE3F2FD),
  Color(0xFFFCE4EC),
  Color(0xFFF3E5F5),
  Color(0xFFFFF8E1),
  Color(0xFFE0F7FA),
  Color(0xFFFBE9E7),
];

// ── Shape config for randomised decorations ────────────────────────────────────

class _ShapeConfig {
  final double? top, bottom, left, right;
  final double size;
  final bool isCircle;

  const _ShapeConfig({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.isCircle,
  });
}

/// Exactly 4 shapes, one per quadrant, so they always spread across the card.
List<_ShapeConfig> _shapesForCard(int seed) {
  final rng = math.Random(seed * 1013 + 37);

  // Card: h≈120. We split into 4 quadrants (top-left, top-right,
  // bottom-left, bottom-right) and place one shape randomly in each.
  // Quadrant half-sizes (px): vertical split at 60, horizontal split at 140.
  const double hHalf = 60;  // card height / 2
  const double wHalf = 140; // approximate half-width

  // For each quadrant: [useTop, useLeft]
  const quadrants = [
    [true, true],   // top-left
    [true, false],  // top-right
    [false, true],  // bottom-left
    [false, false], // bottom-right
  ];

  return List.generate(4, (i) {
    final size = 12.0 + rng.nextDouble() * 22; // 12–34 px
    final isCircle = rng.nextBool();
    final useTop  = quadrants[i][0];
    final useLeft = quadrants[i][1];

    // Random offset within the quadrant, allow slight overflow at edges
    final vOffset = -size * 0.3 + rng.nextDouble() * (hHalf + size * 0.3);
    final hOffset = -size * 0.3 + rng.nextDouble() * (wHalf + size * 0.3);

    return _ShapeConfig(
      top:    useTop    ? vOffset : null,
      bottom: !useTop   ? vOffset : null,
      left:   useLeft   ? hOffset : null,
      right:  !useLeft  ? hOffset : null,
      size: size,
      isCircle: isCircle,
    );
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class CuisineMealsScreen extends StatefulWidget {
  final int cuisineId;
  const CuisineMealsScreen({super.key, required this.cuisineId});

  @override
  State<CuisineMealsScreen> createState() => _CuisineMealsScreenState();
}

class _CuisineMealsScreenState extends State<CuisineMealsScreen> {
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<FavoritesRepository>().ensureLoaded();

      final vm = context.read<CuisineViewModel>();
      if (vm.cuisines.isEmpty) await vm.loadCuisines();
      final cuisine = vm.cuisines.firstWhere(
        (c) => c.id == widget.cuisineId,
        orElse: () => vm.cuisines.first,
      );
      vm.loadDishesByCuisine(cuisine);
    });
  }

  void _clearCategory(CuisineViewModel vm) {
    setState(() => _selectedCategory = '');
    final cuisine = vm.selectedCuisine;
    if (cuisine != null) vm.loadDishesByCuisine(cuisine);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Consumer<CuisineViewModel>(
      builder: (context, vm, _) {
        final cuisine = vm.selectedCuisine;

        // Primary: categories from the cuisine_categories junction table.
        // Fallback: unique categories derived from the loaded dishes themselves
        // (handles the case where junction tables haven't synced yet).
        final categories = vm.categories.isNotEmpty
            ? vm.categories
            : (vm.dishes
                    .expand((d) => d.categories)
                    .toSet()
                    .toList()
                  ..sort());

        final filtered = _selectedCategory.isEmpty
            ? vm.dishes
            : vm.dishes
                .where((d) => d.categories.contains(_selectedCategory))
                .toList();

        final hasFilter = _selectedCategory.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.white,
          // ── Navigation bar — outside CustomScrollView ──────────────
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, topPadding > 0 ? 0 : 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cuisine != null ? '${cuisine.name} Cuisine' : '',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          body: CustomScrollView(
            slivers: [
              // ── Category label + chips + clear link ───────────────────
              if (categories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ),

                // Horizontal chip list
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = categories[i];
                        final active = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 0),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: active ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                height: 1.0,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // "Clear" link below chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: hasFilter ? () => _clearCategory(vm) : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: hasFilter ? 1.0 : 0.35,
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: hasFilter
                                    ? AppColors.error
                                    : AppColors.textHint,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasFilter
                                    ? AppColors.error
                                    : AppColors.textHint,
                              ),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Dish list ─────────────────────────────────────────────
              if (vm.isLoading)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                )
              else if (vm.hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('😕', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(vm.errorMessage ?? AppStrings.genericError),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (cuisine != null) vm.loadDishesByCuisine(cuisine);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final dish = filtered[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Consumer<FavoritesRepository>(
                            builder: (context, favRepo, _) => _DishCard(
                              dish: dish,
                              bgColor: _cardColors[i % _cardColors.length],
                              isFavorite: favRepo.isFavoriteSync(dish.id),
                              onFavoriteTap: () => favRepo.toggleFavorite(dish),
                              onTap: () => context.push(
                                AppRouter.detail
                                    .replaceFirst(':id', '${dish.id}'),
                                extra: dish,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Dish card ──────────────────────────────────────────────────────────────────

class _DishCard extends StatelessWidget {
  final Dish dish;
  final Color bgColor;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _DishCard({
    required this.dish,
    required this.bgColor,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final shapes = _shapesForCard(dish.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Randomised decorative background shapes
            for (final s in shapes)
              Positioned(
                top: s.top,
                bottom: s.bottom,
                left: s.left,
                right: s.right,
                child: _Shape(
                    size: s.size, color: bgColor, isCircle: s.isCircle),
              ),

            // Content row
            Row(
              children: [
                // Left: text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dish.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            dish.primaryCategory,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.menu_book_rounded,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Recipe',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: image + favourite button stacked
                SizedBox(
                  width: 108, // enough room for image + fav button margin
                  child: Stack(
                    children: [
                      // Image — shifted left to leave room for fav button
                      Positioned(
                        top: 12,
                        bottom: 12,
                        left: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: dish.thumbnailUrl,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 84,
                              height: 84,
                              color: Colors.black.withOpacity(0.06),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 84,
                              height: 84,
                              color: Colors.black.withOpacity(0.06),
                              child: const Icon(Icons.restaurant,
                                  color: AppColors.textHint, size: 32),
                            ),
                          ),
                        ),
                      ),

                      // Favourite button — top-right, clear of image
                      Positioned(
                        top: 6,
                        right: 4,
                        child: GestureDetector(
                          onTap: onFavoriteTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isFavorite
                                  ? AppColors.error.withOpacity(0.12)
                                  : Colors.white.withOpacity(0.85),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 14,
                              color: isFavorite
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Shape extends StatelessWidget {
  final double size;
  final Color color;
  final bool isCircle;

  const _Shape(
      {required this.size, required this.color, this.isCircle = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.black, 0.05),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(size * 0.3),
      ),
    );
  }
}
