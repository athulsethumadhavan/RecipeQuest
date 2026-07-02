import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/cuisine_model.dart';
import '../../../data/models/dish_model.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/payment_service.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../auth/auth_bottom_sheet.dart';
import 'widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _titleTapCount = 0;
  bool _searchVisible = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late final AnimationController _searchAnim;
  late final Animation<double> _searchFade;

  @override
  void initState() {
    super.initState();
    _searchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _searchFade = CurvedAnimation(parent: _searchAnim, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
    });
  }

  @override
  void dispose() {
    _searchAnim.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onTitleDoubleTap() {
    _titleTapCount++;
    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      context.push(AppRouter.admin);
    }
  }

  void _toggleSearch() {
    setState(() => _searchVisible = !_searchVisible);
    if (_searchVisible) {
      _searchAnim.forward();
      Future.delayed(const Duration(milliseconds: 80),
          () => _searchFocus.requestFocus());
    } else {
      _searchAnim.reverse();
      _searchFocus.unfocus();
      _searchCtrl.clear();
      context.read<HomeViewModel>().clearSearch();
    }
  }

  void _onDishTap(BuildContext context, Dish dish) {
    final vm = context.read<HomeViewModel>();
    if (vm.isCuisineSubscribed(dish.cuisineId)) {
      _goToDetail(dish);
    } else {
      _showPaywall(context, dish);
    }
  }

  void _goToDetail(Dish dish) {
    context.push(
      AppRouter.detail.replaceFirst(':id', '${dish.id}'),
      extra: dish,
    );
  }

  Future<void> _showPaywall(BuildContext context, Dish dish) async {
    // Auth gate: must be signed in before purchasing
    if (!AuthService.instance.isLoggedIn) {
      final loggedIn = await AuthBottomSheet.show(context);
      if (loggedIn != true || !mounted) return;
      // Merge local favourites into Supabase now that user is signed in
      await context.read<FavoritesRepository>().onLogin();
    }

    if (!mounted) return;
    final favRepo = context.read<FavoritesRepository>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaywallSheet(
        dish: dish,
        favoritesRepository: favRepo,
        onUnlocked: () {
          Navigator.pop(context);
          _goToDetail(dish);
        },
        onDismissed: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hp = Responsive.horizontalPadding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hp, isTablet ? 28 : 20, hp, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _IconBtn(
                        icon: Icons.menu_rounded,
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 10),
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
                      const Spacer(),
                      _IconBtn(
                        icon: _searchVisible
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        onTap: _toggleSearch,
                      ),
                      const SizedBox(width: 10),
                      _IconBtn(
                        icon: Icons.favorite_border_rounded,
                        onTap: () => context.push(AppRouter.favorites),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onDoubleTap: _onTitleDoubleTap,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'What do you want\ncooking today?',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                            height: 1.25,
                            fontSize: isTablet
                                ? 32
                                : (MediaQuery.of(context).size.width * 0.06)
                                    .clamp(20.0, 26.0),
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Inline search bar ─────────────────────────────────────────
            FadeTransition(
              opacity: _searchFade,
              child: SizeTransition(
                sizeFactor: _searchFade,
                axisAlignment: -1,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                  child: Container(
                    height: isTablet ? 54 : 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search_rounded,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: (q) =>
                                context.read<HomeViewModel>().search(q),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: AppColors.textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search dishes…',
                              contentPadding: EdgeInsets.zero,
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 15),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        // Clear button
                        ValueListenableBuilder(
                          valueListenable: _searchCtrl,
                          builder: (_, v, __) => v.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    context
                                        .read<HomeViewModel>()
                                        .clearSearch();
                                  },
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: Icon(Icons.cancel_rounded,
                                        color: AppColors.textSecondary,
                                        size: 18),
                                  ),
                                )
                              : const SizedBox(width: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Body: search results OR cuisine grid ──────────────────────
            Expanded(
              child: Consumer<HomeViewModel>(
                builder: (context, vm, _) {
                  // ── Search results ──────────────────────────────────────
                  if (_searchVisible &&
                      (_searchCtrl.text.isNotEmpty ||
                          vm.isSearching ||
                          vm.searchResults.isNotEmpty)) {
                    return _SearchResults(
                      vm: vm,
                      onDishTap: (dish) => _onDishTap(context, dish),
                    );
                  }

                  // ── Cuisine section label ───────────────────────────────
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hp),
                        child: Text(
                          'Popular Cuisine',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: isTablet ? 22 : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _CuisineGrid(vm: vm),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

// ── Search results list ───────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final HomeViewModel vm;
  final ValueChanged<Dish> onDishTap;

  const _SearchResults({required this.vm, required this.onDishTap});

  @override
  Widget build(BuildContext context) {
    if (vm.isSearching) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (vm.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No dishes found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    final hp = Responsive.horizontalPadding(context);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hp, 0, hp, 32),
      itemCount: vm.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final dish = vm.searchResults[i];
        final locked = !vm.isCuisineSubscribed(dish.cuisineId);
        return _DishResultTile(
          dish: dish,
          locked: locked,
          onTap: () => onDishTap(dish),
        );
      },
    );
  }
}

class _DishResultTile extends StatelessWidget {
  final Dish dish;
  final bool locked;
  final VoidCallback onTap;

  const _DishResultTile({
    required this.dish,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: SizedBox(
                width: 88,
                height: 88,
                child: CachedNetworkImage(
                  imageUrl: dish.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      color: AppColors.primary.withOpacity(0.1)),
                  errorWidget: (_, __, ___) => Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.restaurant_rounded,
                          color: AppColors.primary)),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dish.cuisineName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (dish.primaryCategory.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dish.primaryCategory,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Lock icon for non-subscribed cuisines
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: locked
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: Colors.orange, size: 18),
                    )
                  : const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cuisine grid ──────────────────────────────────────────────────────────────

class _CuisineGrid extends StatelessWidget {
  final HomeViewModel vm;
  const _CuisineGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
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

    final hp = Responsive.horizontalPadding(context);
    final cols = Responsive.cuisineGridColumns(context);
    final isTablet = Responsive.isTablet(context);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: vm.refresh,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(hp, 0, hp, 32),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: isTablet ? 20 : 16,
          crossAxisSpacing: isTablet ? 20 : 16,
          childAspectRatio: 1.0,
        ),
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
          final cuisine = vm.cuisines[i];
          return _CuisineCard(
            cuisine: cuisine,
            onTap: () => context.push(
              AppRouter.cuisineMeals.replaceFirst(':id', '${cuisine.id}'),
              extra: cuisine,
            ),
          );
        },
      ),
    );
  }
}

// ── Paywall bottom sheet ──────────────────────────────────────────────────────

class _PaywallSheet extends StatefulWidget {
  final Dish dish;
  final FavoritesRepository favoritesRepository;
  final VoidCallback onUnlocked;
  final VoidCallback onDismissed;

  const _PaywallSheet({
    required this.dish,
    required this.favoritesRepository,
    required this.onUnlocked,
    required this.onDismissed,
  });

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  bool _purchasing = false;

  Future<void> _purchase() async {
    setState(() => _purchasing = true);

    // On simulators / debug builds the store is unavailable.
    // Bypass payment so the full flow can be tested without a real device.
    if (!PaymentService.isAvailable) {
      assert(() {
        // Debug-only bypass: simulate a successful purchase.
        Future.microtask(() async {
          await widget.favoritesRepository.addFavorite(widget.dish);
          if (mounted) widget.onUnlocked();
        });
        return true;
      }());
      // In release builds the store really is unavailable — show the dialog.
      if (const bool.fromEnvironment('dart.vm.product')) {
        setState(() => _purchasing = false);
        _showStoreUnavailableDialog();
      }
      return;
    }

    await PaymentService.purchaseDishAccess(
      onSuccess: () async {
        await widget.favoritesRepository.addFavorite(widget.dish);
        if (mounted) widget.onUnlocked();
      },
      onFailed: () {
        if (mounted) {
          setState(() => _purchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase cancelled or failed. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _showStoreUnavailableDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Store Unavailable'),
        content: const Text(
          'In-app purchases are not available on this device. '
          'Please ensure you are signed into the App Store / Google Play.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = PaymentService.displayPrice;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Lock icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded,
                color: Colors.orange, size: 36),
          ),

          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.dish.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'This recipe is from ${widget.dish.cuisineName} cuisine. '
              'Pay $price to unlock this recipe and save it to your favourites.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ),

          const SizedBox(height: 32),

          // Unlock button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _purchasing ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _purchasing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Unlock & Add to Favourites for $price',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: widget.onDismissed,
            child: Text(
              'Not now',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
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
              CachedNetworkImage(
                imageUrl: cuisine.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: cuisine.startColor.withOpacity(0.4)),
                errorWidget: (_, __, ___) =>
                    Container(color: cuisine.startColor.withOpacity(0.4)),
              ),
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
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
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
