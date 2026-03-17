import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/exceptions.dart';
import '../models/review.dart';

class ReviewRepository {
  final _client = Supabase.instance.client;

  Future<List<Review>> getProductReviews(int productId) async {
    try {
      final rows = await _client
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      return rows.map((r) => Review.fromRow(r)).toList();
    } catch (e) {
      throw ReviewException('Error al cargar reseñas: $e');
    }
  }

  Future<void> addReview({
    required String userId,
    required String userEmail,
    required int    productId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _client.from('reviews').insert({
        'user_id':    userId,
        'user_email': userEmail,
        'product_id': productId,
        'rating':     rating,
        'comment':    comment,
      });
    } catch (e) {
      throw ReviewException('No se pudo publicar la reseña: $e');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _client.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      throw ReviewException('No se pudo eliminar la reseña: $e');
    }
  }

  Future<bool> userHasReviewed(String userId, int productId) async {
    try {
      final result = await _client
          .from('reviews')
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
