import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../viewmodels/cuisine_viewmodel.dart';

class CuisineListScreen extends StatefulWidget {
  const CuisineListScreen({super.key});

  @override
  State<CuisineListScreen> createState() => _CuisineListScreenState();
}

class _CuisineListScreenState extends State<CuisineListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuisineViewModel>().loadCuisines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.cuisinesTitle,
                          style: Theme.of(context).textTheme.displayMedium),
                      Text(AppStrings.cuisinesSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<CuisineViewModel>(
                  builder: (context, vm, _) {
                    if (vm.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      );
                    }
                    if (vm.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('😕',
                                style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(vm.errorMessage ?? AppStrings.genericError),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: vm.loadCuisines,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: vm.cuisines.length,
                      itemBuilder: (context, i) {
                        final cuisine = vm.cuisines[i];
                        return GestureDetector(
                          onTap: () => context.push(
                            AppRouter.cuisineMeals
                                .replaceFirst(':id', '${cuisine.id}'),
                            extra: cuisine,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: cuisine.gradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: cuisine.startColor.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(cuisine.flag,
                                    style: const TextStyle(fontSize: 36)),
                                const SizedBox(height: 8),
                                Text(
                                  cuisine.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${cuisine.description.substring(0, 30)}…',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color:
                                              Colors.white.withOpacity(0.8)),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
