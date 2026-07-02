import '../../data/models/cuisine_model.dart';
import '../../data/models/dish_model.dart';
import '../../data/repositories/cuisine_repository.dart';
import '../../data/repositories/preference_repository.dart';
import '../../data/services/auth_service.dart';
import 'base_viewmodel.dart';

class HomeViewModel extends BaseViewModel {
  final CuisineRepository _repository;
  final PreferenceRepository _prefRepository;
  final AuthService _authService;

  HomeViewModel({
    CuisineRepository? repository,
    required PreferenceRepository prefRepository,
    required AuthService authService,
  })  : _repository = repository ?? CuisineRepository(),
        _prefRepository = prefRepository,
        _authService = authService {
    _prefRepository.addListener(_onPreferencesChanged);
    // Refresh cuisines whenever login state changes
    _authService.addListener(_onAuthChanged);
  }

  // ── Cuisine list ───────────────────────────────────────────────────────────
  List<Cuisine> _cuisines = [];
  List<Cuisine> get cuisines => _cuisines;

  /// IDs selected during onboarding (used to filter when signed out).
  List<int> _selectedCuisineIds = [];
  List<int> get subscribedCuisineIds => _selectedCuisineIds;

  // ── Dish search ────────────────────────────────────────────────────────────
  List<Dish> _searchResults = [];
  List<Dish> get searchResults => _searchResults;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // ── Init ───────────────────────────────────────────────────────────────────
  void _onPreferencesChanged() => refresh();
  void _onAuthChanged() => refresh();

  Future<void> init() async {
    setLoading();
    try {
      final all = await _repository.getCuisines();
      final selectedIds = await _prefRepository.getSelectedCuisineIds();
      _selectedCuisineIds = selectedIds;

      if (_authService.isLoggedIn) {
        // Signed in: show all cuisines, purchases tracked via selectedIds
        _cuisines = all;
      } else {
        // Signed out: show only onboarding-selected cuisines
        _cuisines = selectedIds.isEmpty
            ? all
            : all.where((c) => selectedIds.contains(c.id)).toList();
      }

      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _repository.searchDishes(query);
    } catch (_) {
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// When signed in: all cuisines are accessible (purchased ones unlocked).
  /// When signed out: only onboarding-selected cuisines are shown.
  bool isCuisineSubscribed(int cuisineId) {
    if (_authService.isLoggedIn) {
      return _selectedCuisineIds.isEmpty || _selectedCuisineIds.contains(cuisineId);
    }
    return _selectedCuisineIds.isEmpty || _selectedCuisineIds.contains(cuisineId);
  }

  Future<void> refresh() async => init();

  @override
  void dispose() {
    _prefRepository.removeListener(_onPreferencesChanged);
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
