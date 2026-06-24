import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/cuisine_model.dart';
import '../../viewmodels/cuisine_viewmodel.dart';

class CuisineMealsScreen extends StatefulWidget {
  final int cuisineId;

  const CuisineMealsScreen({super.key, required this.cuisineId});

  @override
  State<CuisineMealsScreen> createState() => _CuisineMealsScreenState();
}

class _CuisineMealsScreenState extends State<CuisineMealsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<CuisineViewModel>();
      // Load cuisines first if not already loaded
      if (vm.cuisines.isEmpty) await vm.loadCuisines();
      final cuisine = vm.cuisines.firstWhere(
        (c) => c.id == widget.cuisineId,
        orElse: () => vm.cuisines.first,
      );
      vm.loadDishesByCuisine(cuisine);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CuisineViewModel>(
      builder: (context, vm, _) {
        final cuisine = vm.selectedCuisine;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Gradient hero header
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: cuisine?.startColor ?? AppColors.primary,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: cuisine == null
                      ? Container(color: AppColors.primary)
                      : Container(
                          decoration: BoxDecoration(gradient: cuisine.gradient),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 48),
                              Text(cuisine.flag,
                                  style: const TextStyle(fontSize: 48)),
                              const SizedBox(height: 8),
                              Text(
                                '${cuisine.name} Cuisine',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

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
                            if (cuisine != null) {
                              vm.loadDishesByCuisine(cuisine);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final dish = vm.dishes[i];
                        return GestureDetector(
                          onTap: () => context.push(
                            AppRouter.detail
                                .replaceFirst(':id', '${dish.id}'),
                            extra: dish,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: CachedNetworkImage(
                                      imageUrl: dish.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder: (_, __) => Container(
                                          color: AppColors.surfaceVariant),
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppColors.surfaceVariant,
                                        child: const Icon(Icons.restaurant,
                                            color: AppColors.textHint),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dish.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(dish.category,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: vm.dishes.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.82,
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
