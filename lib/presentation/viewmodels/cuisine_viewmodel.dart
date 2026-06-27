import '../../data/models/cuisine_model.dart';
import '../../data/models/dish_model.dart';
import '../../data/repositories/cuisine_repository.dart';
import 'base_viewmodel.dart';

class CuisineViewModel extends BaseViewModel {
  final CuisineRepository _repository;

  CuisineViewModel({CuisineRepository? repository})
      : _repository = repository ?? CuisineRepository();

  List<Cuisine> _cuisines = [];
  List<Dish> _dishes = [];
  List<String> _categories = [];
  Cuisine? _selectedCuisine;

  List<Cuisine> get cuisines => _cuisines;
  List<Dish> get dishes => _dishes;
  List<String> get categories => _categories;
  Cuisine? get selectedCuisine => _selectedCuisine;

  Future<void> loadCuisines() async {
    setLoading();
    try {
      _cuisines = await _repository.getCuisines();
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Reload whichever screen is currently visible (called after Realtime sync).
  Future<void> refresh() async {
    if (_selectedCuisine != null) {
      await loadDishesByCuisine(_selectedCuisine!);
    } else if (_cuisines.isNotEmpty) {
      await loadCuisines();
    }
  }

  Future<void> loadDishesByCuisine(Cuisine cuisine) async {
    _selectedCuisine = cuisine;
    setLoading();
    try {
      _dishes = await _repository.getDishesByCuisine(cuisine.id);
      _categories = await _repository.getCategoriesForCuisine(cuisine.id);
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }
}
