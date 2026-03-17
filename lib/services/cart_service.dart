import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

const _kBaseUrl = 'https://fakestoreapi.com';

class CartService extends ChangeNotifier {
  final _client = Supabase.instance.client;

  final List<CartItem> _items = [];
  String? _userId;
  bool isLoading = false;

  List<CartItem> get items       => List.unmodifiable(_items);
  double         get total       => _items.fold(0, (s, i) => s + i.subtotal);
  int            get itemCount   => _items.fold(0, (s, i) => s + i.quantity);
  bool           get isEmpty     => _items.isEmpty;
  String         get formattedTotal => '\$${total.toStringAsFixed(2)}';

  void initialize(String userId) {
    _userId = userId;
    _loadFromSupabase();
  }

  Future<void> _loadFromSupabase() async {
    if (_userId == null) return;
    isLoading = true;
    notifyListeners();

    try {
      final cartRows = await _client
          .from('cart')
          .select()
          .eq('user_id', _userId!);

      if (cartRows.isEmpty) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final productIds = cartRows.map((r) => r['product_id']).toList();
      final products   = await _fetchProductsBatch(productIds.cast<int>());

      _items.clear();
      for (final row in cartRows) {
        final product = products[row['product_id'] as int];
        if (product != null) {
          _items.add(CartItem(
            id:       row['id'].toString(),
            product:  product,
            quantity: row['quantity'] as int,
          ));
        }
      }
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  Future<Map<int, Product>> _fetchProductsBatch(List<int> ids) async {
    final results = await Future.wait(
      ids.map((id) => http
          .get(Uri.parse('$_kBaseUrl/products/$id'))
          .then((r) {
            if (r.statusCode == 200) {
              return Product.fromJson(json.decode(r.body) as Map<String, dynamic>);
            }
            return null;
          })
          .catchError((_) => null)),
    );
    final map = <int, Product>{};
    for (final product in results) {
      if (product != null) map[product.id] = product;
    }
    return map;
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    final existingIndex = _items.indexWhere((x) => x.product.id == product.id);

    if (existingIndex >= 0) {
      final updated = _items[existingIndex].copyWithQuantity(
        _items[existingIndex].quantity + quantity,
      );
      _items[existingIndex] = updated;
      notifyListeners();

      if (_userId != null) {
        try {
          final rows = await _client
              .from('cart')
              .select('id,quantity')
              .eq('user_id', _userId!)
              .eq('product_id', product.id);
          if (rows.isNotEmpty) {
            await _client
                .from('cart')
                .update({'quantity': updated.quantity})
                .eq('id', rows[0]['id']);
          }
        } catch (_) {}
      }
    } else {
      final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
      _items.add(CartItem(id: tempId, product: product, quantity: quantity));
      notifyListeners();

      if (_userId != null) {
        try {
          final result = await _client.from('cart').insert({
            'user_id':    _userId!,
            'product_id': product.id,
            'quantity':   quantity,
          }).select();

          final idx = _items.indexWhere((x) => x.id == tempId);
          if (idx >= 0 && result.isNotEmpty) {
            _items[idx] = CartItem(
              id:       result[0]['id'].toString(),
              product:  product,
              quantity: quantity,
            );
            notifyListeners();
          }
        } catch (_) {}
      }
    }
  }

  Future<void> updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(item);
      return;
    }
    final index = _items.indexWhere((x) => x.id == item.id);
    if (index < 0) return;

    _items[index] = item.copyWithQuantity(newQuantity);
    notifyListeners();

    if (_userId != null && !item.id.startsWith('tmp_')) {
      try {
        await _client.from('cart').update({'quantity': newQuantity}).eq('id', item.id);
      } catch (_) {}
    }
  }

  Future<void> removeItem(CartItem item) async {
    _items.removeWhere((x) => x.id == item.id);
    notifyListeners();

    if (_userId != null && !item.id.startsWith('tmp_')) {
      try {
        await _client.from('cart').delete().eq('id', item.id);
      } catch (_) {}
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();

    if (_userId != null) {
      try {
        await _client.from('cart').delete().eq('user_id', _userId!);
      } catch (_) {}
    }
  }

  void reset() {
    _items.clear();
    _userId = null;
    notifyListeners();
  }
}
