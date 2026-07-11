import '../../data/models/dish_model.dart';
import '../../data/models/dish_detail_model.dart';
import '../../data/repositories/cuisine_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/services/analytics_service.dart';
import 'base_viewmodel.dart';

class DetailViewModel extends BaseViewModel {
  final CuisineRepository _repository;
  final FavoritesRepository _favoritesRepository;

  DetailViewModel({
    CuisineRepository? repository,
    FavoritesRepository? favoritesRepository,
  })  : _repository = repository ?? CuisineRepository(),
        _favoritesRepository = favoritesRepository ?? FavoritesRepository();

  DishDetail? _detail;
  bool _isFavorite = false;
  List<Dish> _relatedDishes = [];

  DishDetail? get detail => _detail;
  bool get isFavorite => _isFavorite;
  List<Dish> get relatedDishes => _relatedDishes;

  Future<void> loadDish(int dishId) async {
    setLoading();
    try {
      _detail = await _repository.getDishDetail(dishId);
      _isFavorite = await _favoritesRepository.isFavorite(dishId);
      _loadRelated(_detail!.dishId, _detail!.cuisineId);
      AnalyticsService.instance.logDishView(
        dishId: _detail!.dishId,
        dishName: _detail!.dishName,
        cuisineName: _detail!.cuisineName,
      );
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> _loadRelated(int dishId, int cuisineId) async {
    try {
      _relatedDishes = await _repository.getRelatedDishes(dishId, cuisineId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavorite() async {
    if (_detail == null) return;
    final dish = Dish(
      id: _detail!.dishId,
      cuisineId: _detail!.cuisineId,
      name: _detail!.dishName,
      thumbnailUrl: _detail!.thumbnailUrl,
      categories: _detail!.categories,
      shortDescription: _detail!.shortDescription,
      cuisineName: _detail!.cuisineName,
    );
    if (_isFavorite) {
      await _favoritesRepository.removeFavorite(_detail!.dishId);
      _isFavorite = false;
      AnalyticsService.instance.logFavoriteRemoved(
        dishId: _detail!.dishId,
        dishName: _detail!.dishName,
      );
    } else {
      await _favoritesRepository.addFavorite(dish);
      _isFavorite = true;
      AnalyticsService.instance.logFavoriteAdded(
        dishId: _detail!.dishId,
        dishName: _detail!.dishName,
      );
    }
    notifyListeners();
  }
}
