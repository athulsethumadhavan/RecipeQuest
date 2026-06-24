import 'dart:async';
import '../../data/models/dish_model.dart';
import '../../data/repositories/cuisine_repository.dart';
import 'base_viewmodel.dart';

class SearchViewModel extends BaseViewModel {
  final CuisineRepository _repository;
  Timer? _debounce;

  SearchViewModel({CuisineRepository? repository})
      : _repository = repository ?? CuisineRepository();

  List<Dish> _results = [];
  String _query = '';

  List<Dish> get results => _results;
  String get query => _query;
  bool get hasQuery => _query.isNotEmpty;

  void onQueryChanged(String query) {
    _query = query;
    if (query.isEmpty) {
      _results = [];
      setIdle();
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
    notifyListeners();
  }

  Future<void> _search(String query) async {
    setLoading();
    try {
      _results = await _repository.searchDishes(query);
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  void clearSearch() {
    _query = '';
    _results = [];
    _debounce?.cancel();
    setIdle();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
