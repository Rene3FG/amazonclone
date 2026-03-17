import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/exceptions.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override List<Object?> get props => [];
}

class LoadProducts   extends ProductEvent {}
class RefreshProducts extends ProductEvent {}

class FilterByCategory extends ProductEvent {
  final String? category;
  const FilterByCategory(this.category);
  @override List<Object?> get props => [category];
}

class SearchProducts extends ProductEvent {
  final String query;
  const SearchProducts(this.query);
  @override List<Object?> get props => [query];
}

abstract class ProductState extends Equatable {
  const ProductState();
  @override List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading  extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> allProducts;
  final List<Product> displayedProducts;
  final List<Product> deals;
  final List<Product> topRated;
  final List<String>  categories;
  final String?       activeCategory;
  final String        searchQuery;

  const ProductLoaded({
    required this.allProducts,
    required this.displayedProducts,
    required this.deals,
    required this.topRated,
    required this.categories,
    this.activeCategory,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [displayedProducts, activeCategory, searchQuery];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override List<Object?> get props => [message];
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc(this._repository) : super(ProductInitial()) {
    on<LoadProducts>(_onLoad);
    on<RefreshProducts>(_onRefresh);
    on<FilterByCategory>(_onFilter);
    on<SearchProducts>(_onSearch);
  }

  Future<void> _onLoad(LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(RefreshProducts event, Emitter<ProductState> emit) async {
    _repository.clearCache();
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<ProductState> emit) async {
    try {
      final products   = await _repository.fetchAll();
      final categories = await _repository.fetchCategories();
      emit(ProductLoaded(
        allProducts:       products,
        displayedProducts: products,
        deals:             _repository.dealsProducts,
        topRated:          _repository.topRatedProducts,
        categories:        categories,
      ));
    } on AppException catch (e) {
      emit(ProductError(e.message));
    } catch (e) {
      emit(ProductError('Error al cargar productos: $e'));
    }
  }

  void _onFilter(FilterByCategory event, Emitter<ProductState> emit) {
    final current = state;
    if (current is! ProductLoaded) return;

    final filtered = event.category == null
        ? current.allProducts
        : current.allProducts.where((p) => p.category == event.category).toList();

    emit(ProductLoaded(
      allProducts:       current.allProducts,
      displayedProducts: filtered,
      deals:             current.deals,
      topRated:          current.topRated,
      categories:        current.categories,
      activeCategory:    event.category,
    ));
  }

  void _onSearch(SearchProducts event, Emitter<ProductState> emit) {
    final current = state;
    if (current is! ProductLoaded) return;

    final results = event.query.isEmpty
        ? current.allProducts
        : _repository.search(event.query);

    emit(ProductLoaded(
      allProducts:       current.allProducts,
      displayedProducts: results,
      deals:             current.deals,
      topRated:          current.topRated,
      categories:        current.categories,
      activeCategory:    null,
      searchQuery:       event.query,
    ));
  }
}
