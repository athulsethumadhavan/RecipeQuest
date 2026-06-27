import '../../data/models/cuisine_model.dart';
import '../../data/models/dish_model.dart';
import '../../data/repositories/cuisine_repository.dart';
import '../../data/repositories/preference_repository.dart';
import 'base_viewmodel.dart';

class HomeViewModel extends BaseViewModel {
  final CuisineRepository _repository;
  final PreferenceRepository _prefRepository;

  HomeViewModel({
    CuisineRepository? repository,
    required PreferenceRepository prefRepository,
  })  : _repository = repository ?? CuisineRepository(),
        _prefRepository = prefRepository {
    // Auto-refresh whenever the user saves new cuisine preferences
    _prefRepository.addListener(_onPreferencesChanged);
  }

  // ── Cuisine list ───────────────────────────────────────────────────────────
  List<Cuisine> _cuisines = [];
  List<Cuisine> get cuisines => _cuisines;

  /// IDs the user has subscribed to (purchased or selected during onboarding).
  List<int> _subscribedCuisineIds = [];
  List<int> get subscribedCuisineIds => _subscribedCuisineIds;

  // ── Dish search ────────────────────────────────────────────────────────────
  List<Dish> _searchResults = [];
  List<Dish> get searchResults => _searchResults;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // ── Init ───────────────────────────────────────────────────────────────────
  void _onPreferencesChanged() => refresh();

  Future<void> init() async {
    setLoading();
    try {
      final all = await _repository.getCuisines();
      final selectedIds = await _prefRepository.getSelectedCuisineIds();
      _subscribedCuisineIds = selectedIds;
      _cuisines = selectedIds.isEmpty
          ? all
          : all.where((c) => selectedIds.contains(c.id)).toList();
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
  bool isCuisineSubscribed(int cuisineId) =>
      _subscribedCuisineIds.isEmpty || _subscribedCuisineIds.contains(cuisineId);

  Future<void> refresh() async => init();

  @override
  void dispose() {
    _prefRepository.removeListener(_onPreferencesChanged);
    super.dispose();
  }
}
