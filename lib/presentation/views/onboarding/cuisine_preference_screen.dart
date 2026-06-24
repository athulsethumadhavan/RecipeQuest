import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/cuisine_model.dart';
import '../../../data/repositories/cuisine_repository.dart';
import '../../../data/repositories/preference_repository.dart';

class CuisinePreferenceScreen extends StatefulWidget {
  /// When true, shown as a picker from home (multi-select, not first-launch)
  final bool isEditing;

  const CuisinePreferenceScreen({super.key, this.isEditing = false});

  @override
  State<CuisinePreferenceScreen> createState() =>
      _CuisinePreferenceScreenState();
}

class _CuisinePreferenceScreenState extends State<CuisinePreferenceScreen> {
  final _cuisineRepo = CuisineRepository();
  late final PreferenceRepository _prefRepo;

  List<Cuisine> _cuisines = [];

  // Single-select for onboarding
  int? _singleSelected;

  // Multi-select for editing
  Set<int> _multiSelected = {};

  // IDs that were already saved — cannot be deselected in editing mode
  Set<int> _lockedIds = {};

  bool _loading = true;
  bool _saving = false;

  bool get _isMulti => widget.isEditing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefRepo = context.read<PreferenceRepository>();
      _load();
    });
  }

  Future<void> _load() async {
    final cuisines = await _cuisineRepo.getCuisines();
    final savedIds = await _prefRepo.getSelectedCuisineIds();
    setState(() {
      _cuisines = cuisines;
      if (_isMulti) {
        _multiSelected = Set<int>.from(savedIds);
        _lockedIds = Set<int>.from(savedIds); // lock previously saved ones
      } else {
        _singleSelected = savedIds.isNotEmpty ? savedIds.first : null;
      }
      _loading = false;
    });
  }

  bool _isSelected(int id) =>
      _isMulti ? _multiSelected.contains(id) : _singleSelected == id;

  bool _isLocked(int id) => _isMulti && _lockedIds.contains(id);

  void _toggle(int id) {
    if (_isLocked(id)) return; // saved cuisines cannot be removed
    setState(() {
      if (_isMulti) {
        final next = Set<int>.from(_multiSelected);
        if (next.contains(id)) {
          next.remove(id);
        } else {
          next.add(id);
        }
        _multiSelected = next;
      } else {
        _singleSelected = id;
      }
    });
  }

  Future<void> _save() async {
    final ids = _isMulti
        ? _multiSelected.toList()
        : [if (_singleSelected != null) _singleSelected!];

    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one cuisine'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await _prefRepo.completeOnboarding(ids);
    if (mounted) {
      if (widget.isEditing) {
        context.pop();
      } else {
        context.go(AppRouter.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isEditing)
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        Text(
                          widget.isEditing
                              ? 'Your Cuisines'
                              : 'What cuisine do\nyou love? 🍴',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isEditing
                              ? 'Tap to add more cuisines to your list'
                              : 'Select the cuisine you\'re interested in',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Cuisine grid ────────────────────────────────────────
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _cuisines.length,
                      itemBuilder: (context, i) {
                        final cuisine = _cuisines[i];
                        final isSelected = _isSelected(cuisine.id);
                        final isLocked = _isLocked(cuisine.id);

                        return GestureDetector(
                          onTap: () => _toggle(cuisine.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: isSelected ? 16 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Image
                                  CachedNetworkImage(
                                    imageUrl: cuisine.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                        color: cuisine.startColor
                                            .withOpacity(0.4)),
                                    errorWidget: (_, __, ___) => Container(
                                        color: cuisine.startColor
                                            .withOpacity(0.4)),
                                  ),
                                  // Dark overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(
                                              isSelected ? 0.55 : 0.75),
                                        ],
                                        stops: const [0.3, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Selection ring
                                  if (isSelected)
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 3,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(22),
                                      ),
                                    ),
                                  // Badge: lock icon for saved, check for newly added
                                  if (isSelected)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isLocked
                                              ? AppColors.primary
                                              : AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isLocked
                                              ? Icons.lock_rounded
                                              : Icons.check_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                    ),
                                  // Name + subtitle
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 14,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        Text(
                                          isLocked
                                              ? 'Added ✓'
                                              : isSelected
                                                  ? 'Tap to add'
                                                  : 'Tap to select',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Button ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                widget.isEditing ? 'Save' : 'Continue',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
