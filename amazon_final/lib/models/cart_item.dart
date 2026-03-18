import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final String  id;
  final Product product;
  final int     quantity;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  double get subtotal          => product.price * quantity;
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  CartItem copyWithQuantity(int newQty) =>
      CartItem(id: id, product: product, quantity: newQty);

  @override
  List<Object?> get props => [id, product.id, quantity];
}
