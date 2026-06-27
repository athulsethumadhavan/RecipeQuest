import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../home/widgets/shimmer_loader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              const SizedBox(height: 8),
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
                  Text(AppStrings.searchTitle,
                      style: Theme.of(context).textTheme.displayMedium),
                ],
              ),
              const SizedBox(height: 16),

              Consumer<SearchViewModel>(
                builder: (context, vm, _) => TextField(
                  controller: _controller,
                  onChanged: vm.onQueryChanged,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: vm.hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _controller.clear();
                              vm.clearSearch();
                            },
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.search,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Consumer<SearchViewModel>(
                  builder: (context, vm, _) {
                    if (!vm.hasQuery) return _EmptyPrompt();
                    if (vm.isLoading) {
                      return ListView.separated(
                        itemCount: 6,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, __) => const ShimmerBox(
                            width: double.infinity,
                            height: 80,
                            borderRadius: 16),
                      );
                    }
                    if (vm.hasError) {
                      return Center(
                        child: Text(
                          vm.errorMessage ?? AppStrings.genericError,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (vm.results.isEmpty) {
                      return _NoResults(query: vm.query);
                    }
                    return ListView.separated(
                      itemCount: vm.results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final dish = vm.results[i];
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
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(16)),
                                  child: CachedNetworkImage(
                                    imageUrl: dish.thumbnailUrl,
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                        color: AppColors.surfaceVariant),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.surfaceVariant,
                                      child: const Icon(Icons.restaurant),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(dish.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${dish.cuisineName} · ${dish.primaryCategory}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
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

class _EmptyPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Search for recipes',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Try "biryani", "hummus" or "Arabic"',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😔', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(AppStrings.searchEmpty,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('No results for "$query"',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
