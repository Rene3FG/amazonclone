import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import 'package:flutter/material.dart';
import 'product.dart';

class OrderItem extends Equatable {
  final Product product;
  final int     quantity;
  final double  price;
  const OrderItem({required this.product, required this.quantity, required this.price});
  @override
  List<Object?> get props => [product.id, quantity];
}

enum OrderStatus { processing, shipped, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.processing => 'Procesando',
    OrderStatus.shipped    => 'En camino',
    OrderStatus.delivered  => 'Entregado',
    OrderStatus.cancelled  => 'Cancelado',
  };
  Color get color => switch (this) {
    OrderStatus.processing => AppColors.orange,
    OrderStatus.shipped    => AppColors.blue,
    OrderStatus.delivered  => AppColors.green,
    OrderStatus.cancelled  => AppColors.danger,
  };
  IconData get icon => switch (this) {
    OrderStatus.processing => Icons.inventory_2_outlined,
    OrderStatus.shipped    => Icons.local_shipping_outlined,
    OrderStatus.delivered  => Icons.check_circle_outline,
    OrderStatus.cancelled  => Icons.cancel_outlined,
  };
}

class Order extends Equatable {
  final String          id;
  final DateTime        createdAt;
  final double          total;
  final List<OrderItem> items;
  final OrderStatus     status;

  const Order({
    required this.id,
    required this.createdAt,
    required this.total,
    required this.items,
    this.status = OrderStatus.processing,
  });

  String get shortId {
    final clean = id.replaceAll('-', '');
    return '#${clean.substring(0, clean.length.clamp(0, 8)).toUpperCase()}';
  }

  String get formattedDate  => DateFormat('d MMM yyyy').format(createdAt);
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';

  factory Order.fromRow(Map<String, dynamic> row, List<OrderItem> items) {
    
    final rawStatus = row['status'];
    final statusInt = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus?.toString() ?? '0') ?? 0;

    return Order(
      id:        row['id'].toString(),
      createdAt: DateTime.parse(row['created_at'] as String),
      total:     (row['total_amount'] as num).toDouble(),
      items:     items,
      status:    OrderStatus.values[statusInt.clamp(0, OrderStatus.values.length - 1)],
    );
  }

  @override
  List<Object?> get props => [id, createdAt, total, status];
}

class SavedCard extends Equatable {
  final String last4, brand, holder, expiry;
  const SavedCard({required this.last4, required this.brand, required this.holder, required this.expiry});
  @override
  List<Object?> get props => [last4, brand];
}

class ShippingAddress extends Equatable {
  final String name, street, city, zip, country;
  const ShippingAddress({
    required this.name, required this.street,
    required this.city, required this.zip, required this.country,
  });
  String get full => '$street, $city $zip, $country';
  @override
  List<Object?> get props => [street, city];
}
