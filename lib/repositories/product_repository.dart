import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/exceptions.dart';
import '../models/product.dart';

const _kBaseUrl = 'https://fakestoreapi.com';

class ProductRepository {
  final _httpClient = http.Client();
  final _cache      = <int, Product>{};
  List<Product> _allProducts = [];

  List<Product> get allProducts => List.unmodifiable(_allProducts);

  Future<List<Product>> fetchAll() async {
    if (_allProducts.isNotEmpty) return _allProducts;
    try {
      final response = await _httpClient
          .get(Uri.parse('$_kBaseUrl/products'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw NetworkException('Error HTTP ${response.statusCode}');
      }
      final list = json.decode(response.body) as List;
      _allProducts = list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final p in _allProducts) {
        _cache[p.id] = p;
      }
      return _allProducts;
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('No se pudo cargar los productos: $e');
    }
  }

  Future<Product> getById(int id) async {
    if (_cache.containsKey(id)) return _cache[id]!;
    await fetchAll();
    if (_cache.containsKey(id)) return _cache[id]!;
    throw NetworkException('Producto $id no encontrado');
  }

  Future<List<String>> fetchCategories() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$_kBaseUrl/products/categories'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      return (json.decode(response.body) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  List<Product> search(String query) {
    final term = query.toLowerCase().trim();
    if (term.isEmpty) return _allProducts;
    return _allProducts.where((p) =>
      p.title.toLowerCase().contains(term) ||
      p.category.toLowerCase().contains(term) ||
      p.description.toLowerCase().contains(term),
    ).toList();
  }

  List<Product> filterByCategory(String? category) {
    if (category == null) return _allProducts;
    return _allProducts.where((p) => p.category == category).toList();
  }

  List<Product> get dealsProducts =>
      _allProducts.where((p) => p.hasDiscount).toList();

  List<Product> get topRatedProducts =>
      (List.of(_allProducts)
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0)))
        .take(10)
        .toList();

  void clearCache() {
    _allProducts = [];
    _cache.clear();
  }
}
