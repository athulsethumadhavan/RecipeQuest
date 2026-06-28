import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/preference_repository.dart';
import '../../../data/services/payment_service.dart';
import '../../viewmodels/cuisine_viewmodel.dart';

class CuisineListScreen extends StatefulWidget {
  const CuisineListScreen({super.key});

  @override
  State<CuisineListScreen> createState() => _CuisineListScreenState();
}

class _CuisineListScreenState extends State<CuisineListScreen> {
  Set<int> _subscribedIds = {};
  Set<int> _selectedIds   = {}; // unsubscribed cuisines selected for purchase
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<CuisineViewModel>().loadCuisines();
      final ids = await context.read<PreferenceRepository>().getSelectedCuisineIds();
      if (mounted) setState(() => _subscribedIds = ids.toSet());
    });
  }

  // ── price helpers ──────────────────────────────────────────────────────────

  String get _pricePerCuisine => PaymentService.cuisineDisplayPrice;

  double? get _rawPrice {
    final cleaned = _pricePerCuisine.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }

  String get _totalPrice {
    final count = _selectedIds.length;
    if (count == 0) return _pricePerCuisine;
    final raw = _rawPrice;
    if (raw != null) return '\$${(raw * count).toStringAsFixed(2)}';
    return '\$${10 * count}.00';
  }

  // ── purchase ───────────────────────────────────────────────────────────────

  void _purchase() async {
    if (_selectedIds.isEmpty || _purchasing) return;
    setState(() => _purchasing = true);

    final prefRepo = context.read<PreferenceRepository>();

    Future<void> doUnlock() async {
      final newIds = {..._subscribedIds, ..._selectedIds}.toList();
      await prefRepo.updateSelectedCuisineIds(newIds);
      if (mounted) {
        setState(() {
          _subscribedIds = newIds.toSet();
          _selectedIds.clear();
          _purchasing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuisines unlocked! Enjoy exploring.')),
        );
      }
    }

    // Debug / simulator bypass
    if (!PaymentService.isCuisineAvailable) {
      assert(() {
        Future.microtask(doUnlock);
        return true;
      }());
      if (const bool.fromEnvironment('dart.vm.product')) {
        setState(() => _purchasing = false);
        _showStoreUnavailableDialog();
      }
      return;
    }

    await PaymentService.purchaseCuisineAccess(
      onSuccess: doUnlock,
      onFailed: () {
        if (mounted) setState(() => _purchasing = false);
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
            'Please try on a real device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
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
                      Text(
                        'Tap a cuisine to subscribe · $_pricePerCuisine each',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Grid + sticky button overlay ────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Consumer<CuisineViewModel>(
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
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
                      final isSubscribed = _subscribedIds.contains(cuisine.id);
                      final isSelected   = _selectedIds.contains(cuisine.id);

                      return GestureDetector(
                        onTap: () {
                          if (isSubscribed) {
                            // Already subscribed → go to meals
                            context.push(
                              AppRouter.cuisineMeals
                                  .replaceFirst(':id', '${cuisine.id}'),
                              extra: cuisine,
                            );
                          } else {
                            // Toggle selection for purchase
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(cuisine.id);
                              } else {
                                _selectedIds.add(cuisine.id);
                              }
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            gradient: cuisine.gradient,
                            borderRadius: BorderRadius.circular(20),
                            // Dim unsubscribed-unselected cards slightly
                            color: (!isSubscribed && !isSelected)
                                ? Colors.black.withOpacity(0.15)
                                : null,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: cuisine.startColor.withOpacity(
                                    isSelected ? 0.55 : 0.30),
                                blurRadius: isSelected ? 16 : 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Overlay for unsubscribed (not selected) cards
                              if (!isSubscribed && !isSelected)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),

                              // Centre content
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(cuisine.flag,
                                        style: const TextStyle(fontSize: 36)),
                                    const SizedBox(height: 6),
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
                                    // Price label on unsubscribed cards
                                    if (!isSubscribed && !isSelected)
                                      Text(
                                        _pricePerCuisine,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Top-right status badge
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isSubscribed
                                        ? Colors.black.withOpacity(0.30)
                                        : isSelected
                                            ? Colors.white
                                            : Colors.black.withOpacity(0.30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isSubscribed
                                        ? Icons.lock_rounded          // subscribed = locked in
                                        : isSelected
                                            ? Icons.check_rounded     // selected for purchase
                                            : Icons.lock_open_rounded, // not yet subscribed
                                    color: isSelected && !isSubscribed
                                        ? AppColors.primary
                                        : Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

                  // ── Subscribe button overlay ─────────────────────────────
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: 20,
                    right: 20,
                    bottom: _selectedIds.isEmpty ? -100 : 16,
                    child: SafeArea(
                      child: GestureDetector(
                        onTap: _purchasing ? null : _purchase,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _purchasing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    'Subscribe for $_totalPrice',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
