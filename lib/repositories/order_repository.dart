import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/exceptions.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import 'product_repository.dart';

class OrderRepository {
  final _client = Supabase.instance.client;

  Future<String> createOrder(
    String userId,
    List<CartItem> items,
    double total, {
    String? shippingAddress,
    String? cardLast4,
  }) async {
    try {
      final orderResult = await _client.from('orders').insert({
        'user_id':      userId,
        'total_amount': total,
        'status':       0,
        if (shippingAddress != null) 'shipping_address': shippingAddress,
        if (cardLast4 != null)       'card_last4': cardLast4,
      }).select();

      final orderId = orderResult[0]['id'].toString();

      await Future.wait(items.map((item) =>
        _client.from('order_items').insert({
          'order_id':   orderId,
          'product_id': item.product.id,
          'quantity':   item.quantity,
          'price':      item.product.price,
        }),
      ));

      return orderId;
    } catch (e) {
      throw OrderException('No se pudo crear el pedido: $e');
    }
  }

  Future<List<Order>> getUserOrders(
      String userId, ProductRepository productRepo) async {
    try {
      final orderRows = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (orderRows.isEmpty) return [];

      final orderIds = orderRows.map((r) => r['id'].toString()).toList();
      final itemRows = await _client
          .from('order_items')
          .select()
          .inFilter('order_id', orderIds);

      final itemsByOrder = <String, List<Map<String, dynamic>>>{};
      for (final row in itemRows) {
        final key = row['order_id'].toString();
        itemsByOrder.putIfAbsent(key, () => []).add(row);
      }

      await productRepo.fetchAll();

      final orders = <Order>[];
      for (final row in orderRows) {
        final orderId    = row['id'].toString();
        final rawItems   = itemsByOrder[orderId] ?? [];
        final orderItems = <OrderItem>[];

        for (final itemRow in rawItems) {
          try {
            
            final rawPid = itemRow['product_id'];
            final pid    = rawPid is int
                ? rawPid
                : int.parse(rawPid.toString());

            final rawQty = itemRow['quantity'];
            final qty    = rawQty is int
                ? rawQty
                : int.parse(rawQty.toString());

            final product = await productRepo.getById(pid);
            orderItems.add(OrderItem(
              product:  product,
              quantity: qty,
              price:    (itemRow['price'] as num).toDouble(),
            ));
          } catch (_) {}
        }

        orders.add(Order.fromRow(row, orderItems));
      }

      return orders;
    } catch (e) {
      throw OrderException('Error al cargar pedidos: $e');
    }
  }
}
