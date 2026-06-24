import '../../data/models/cuisine_model.dart';
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

  List<Cuisine> _cuisines = [];
  List<Cuisine> get cuisines => _cuisines;

  void _onPreferencesChanged() => refresh();

  Future<void> init() async {
    setLoading();
    try {
      final all = await _repository.getCuisines();
      final selectedIds = await _prefRepository.getSelectedCuisineIds();
      _cuisines = selectedIds.isEmpty
          ? all
          : all.where((c) => selectedIds.contains(c.id)).toList();
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> refresh() async => init();

  @override
  void dispose() {
    _prefRepository.removeListener(_onPreferencesChanged);
    super.dispose();
  }
}
