import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class Review extends Equatable {
  final String   id;
  final String   userId;
  final String   userEmail;
  final int      productId;
  final double   rating;
  final String   comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromRow(Map<String, dynamic> row) => Review(
    id:        row['id'].toString(),
    userId:    row['user_id']    as String,
    userEmail: row['user_email'] as String? ?? 'Usuario',
    productId: row['product_id'] as int,
    rating:    (row['rating']   as num).toDouble(),
    comment:   row['comment']   as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  String get formattedDate => DateFormat('d MMM yyyy').format(createdAt);

  String get initials {
    final parts = userEmail.split('@')[0].split('.');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : userEmail[0].toUpperCase();
  }

  @override
  List<Object?> get props => [id, userId, productId];
}
