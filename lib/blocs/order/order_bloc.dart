import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/exceptions.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override List<Object?> get props => [];
}

class LoadOrders extends OrderEvent {}

class PlaceOrder extends OrderEvent {
  final List<CartItem> items;
  final double         total;
  final String?        shippingAddress;
  final String?        cardLast4;
  const PlaceOrder({
    required this.items,
    required this.total,
    this.shippingAddress,
    this.cardLast4,
  });
}

abstract class OrderState extends Equatable {
  const OrderState();
  @override List<Object?> get props => [];
}

class OrderInitial extends OrderState {}
class OrderLoading  extends OrderState {}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  const OrderLoaded(this.orders);
  @override List<Object?> get props => [orders];
}

class OrderPlaced extends OrderState {
  final String orderId;
  const OrderPlaced(this.orderId);
  @override List<Object?> get props => [orderId];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);
  @override List<Object?> get props => [message];
}

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository   _orderRepo;
  final ProductRepository _productRepo;
  final AuthRepository    _authRepo;

  OrderBloc(this._orderRepo, this._productRepo, this._authRepo)
      : super(OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<PlaceOrder>(_onPlaceOrder);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    final userId = _authRepo.currentUser?.id;
    if (userId == null) return;

    emit(OrderLoading());
    try {
      await _productRepo.fetchAll();
      final orders = await _orderRepo.getUserOrders(userId, _productRepo);
      emit(OrderLoaded(orders));
    } on AppException catch (e) {
      emit(OrderError(e.message));
    } catch (e) {
      emit(OrderError('Error al cargar pedidos: $e'));
    }
  }

  Future<void> _onPlaceOrder(PlaceOrder event, Emitter<OrderState> emit) async {
    final userId = _authRepo.currentUser?.id;
    if (userId == null) return;

    emit(OrderLoading());
    try {
      final orderId = await _orderRepo.createOrder(
        userId,
        event.items,
        event.total,
        shippingAddress: event.shippingAddress,
        cardLast4:       event.cardLast4,
      );
      emit(OrderPlaced(orderId));
      add(LoadOrders());
    } on AppException catch (e) {
      emit(OrderError(e.message));
    } catch (e) {
      emit(OrderError('Error al crear pedido: $e'));
    }
  }
}
