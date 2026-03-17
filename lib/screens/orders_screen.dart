import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/order/order_bloc.dart';
import '../core/theme.dart';
import '../models/order.dart';
import '../widgets/shared_widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderBloc>().add(LoadOrders());
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: const Text('Mis pedidos'),
      actions: [
        IconButton(
          icon:      const Icon(Icons.refresh_outlined, color: Colors.white),
          onPressed: () => context.read<OrderBloc>().add(LoadOrders()),
        ),
      ],
    ),
    body: BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading || state is OrderInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        if (state is OrderError) {
          return ErrorBox(
            message: state.message,
            onRetry: () => context.read<OrderBloc>().add(LoadOrders()),
          );
        }
        if (state is OrderLoaded) {
          if (state.orders.isEmpty) {
            return const EmptyState(
              icon:     Icons.receipt_long_outlined,
              title:    'Sin pedidos todavía',
              subtitle: 'Tus compras aparecerán aquí',
            );
          }
          return RefreshIndicator(
            color:     AppColors.orange,
            onRefresh: () async {
              context.read<OrderBloc>().add(LoadOrders());
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: ListView.builder(
              padding:     const EdgeInsets.all(10),
              itemCount:   state.orders.length,
              itemBuilder: (context, i) => SlideIn(
                delay: Duration(milliseconds: i * 50),
                child: OrderCard(order: state.orders[i]),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    ),
  );
}

class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color:        AppColors.card,
      borderRadius: const BorderRadius.all(kR8),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      
      Container(
        padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        AppColors.navy.withOpacity(0.04),
          borderRadius: const BorderRadius.vertical(top: kR8),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PEDIDO ${order.shortId}',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.ink, letterSpacing: 0.5)),
            Text(order.formattedDate,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text('${order.items.length} producto${order.items.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(order.formattedTotal,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:        order.status.color.withOpacity(0.12),
                borderRadius: const BorderRadius.all(kR99),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(order.status.icon, size: 11, color: order.status.color),
                const SizedBox(width: 4),
                Text(order.status.label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: order.status.color)),
              ]),
            ),
          ]),
        ]),
      ),

      if (order.items.isNotEmpty) ...[
        const Divider(height: 1, color: AppColors.line),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            ...order.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 54, height: 54,
                  color:   Colors.grey[50],
                  padding: const EdgeInsets.all(4),
                  child:   CachedNetworkImage(
                    imageUrl:    item.product.imageUrl,
                    fit:         BoxFit.contain,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.product.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(item.product.formattedPrice,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color:        AppColors.bg,
                        borderRadius: const BorderRadius.all(kR4),
                        border:       Border.all(color: AppColors.line),
                      ),
                      child: Text('x${item.quantity}',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ),
                  ]),
                ])),
              ]),
            )),
            if (order.items.length > 3)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '+ ${order.items.length - 3} producto${order.items.length - 3 != 1 ? 's' : ''} más',
                  style: const TextStyle(fontSize: 12, color: AppColors.blue)),
              ),
          ]),
        ),
      ],

      const Divider(height: 1, color: AppColors.line),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side:    const BorderSide(color: AppColors.line),
                shape:   const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(kR4)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Ver detalle',
                  style: TextStyle(fontSize: 12, color: AppColors.ink)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.ink,
                elevation:       0,
                padding:         const EdgeInsets.symmetric(vertical: 8),
                shape:           const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(kR4)),
              ),
              child: const Text('Volver a pedir', style: TextStyle(fontSize: 12)),
            ),
          ),
        ]),
      ),
    ]),
  );
}
