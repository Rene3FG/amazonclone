import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistRepository {
  final _client = Supabase.instance.client;

  Future<List<int>> getWishlistProductIds(String userId) async {
    try {
      final rows = await _client
          .from('wishlist')
          .select('product_id')
          .eq('user_id', userId);
      return rows.map<int>((r) => r['product_id'] as int).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addToWishlist(String userId, int productId) async {
    try {
      await _client.from('wishlist').upsert({
        'user_id':    userId,
        'product_id': productId,
      });
    } catch (_) {}
  }

  Future<void> removeFromWishlist(String userId, int productId) async {
    try {
      await _client
          .from('wishlist')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (_) {}
  }

  Future<bool> isInWishlist(String userId, int productId) async {
    try {
      final result = await _client
          .from('wishlist')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }
}
