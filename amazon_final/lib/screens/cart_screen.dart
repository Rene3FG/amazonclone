import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../blocs/order/order_bloc.dart';
import '../core/theme.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../widgets/shared_widgets.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          Consumer<CartService>(
            builder: (_, cart, __) => cart.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _confirmClear(context, cart),
                    child: const Text('Vaciar',
                        style: TextStyle(color: AppColors.orange)),
                  ),
          ),
        ],
      ),
      body: Consumer<CartService>(
        builder: (context, cart, _) {
          if (cart.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.orange));
          }
          if (cart.isEmpty) {
            return EmptyState(
              icon:        Icons.shopping_cart_outlined,
              title:       'Tu carrito está vacío',
              subtitle:    'Agrega productos para comenzar',
              buttonLabel: 'Explorar',
              onButtonTap: () {},
            );
          }
          return Column(children: [
            Expanded(
              child: ListView.builder(
                padding:     const EdgeInsets.all(10),
                itemCount:   cart.items.length,
                itemBuilder: (context, i) => SlideIn(
                  delay: Duration(milliseconds: i * 40),
                  child: _CartItemCard(item: cart.items[i]),
                ),
              ),
            ),
            _CartFooter(cart: cart),
          ]);
        },
      ),
    );
  }

  void _confirmClear(BuildContext context, CartService cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('¿Vaciar carrito?'),
        content: const Text('Se eliminarán todos los artículos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); cart.clearCart(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Vaciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) => Dismissible(
    key:        Key(item.id),
    direction:  DismissDirection.endToStart,
    onDismissed: (_) {
      HapticFeedback.mediumImpact();
      context.read<CartService>().removeItem(item);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${item.product.title.substring(0, 20)}... eliminado'),
        action:  SnackBarAction(label: 'Deshacer', onPressed: () {}),
      ));
    },
    background: Container(
      alignment: Alignment.centerRight,
      padding:   const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: const BorderRadius.all(kR8),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    ),
    child: Container(
      margin:     const EdgeInsets.only(bottom: 8),
      padding:    const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.card,
        borderRadius: const BorderRadius.all(kR8),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(children: [
        Container(
          width:   65,
          height:  65,
          color:   Colors.grey[50],
          padding: const EdgeInsets.all(6),
          child:   ProductImage(imageUrl: item.product.imageUrl, heroTag: 'c-${item.id}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.title,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.ink)),
            const SizedBox(height: 3),
            const Text('Envío GRATIS',
              style: TextStyle(color: AppColors.blue, fontSize: 11)),
            const SizedBox(height: 8),
            Row(children: [
              _QuantityControl(item: item),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child:    Text(item.formattedSubtotal,
                    key:   ValueKey(item.quantity),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink)),
                ),
                Text('${item.product.formattedPrice} c/u',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ]),
          ]),
        ),
      ]),
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  final CartItem item;
  const _QuantityControl({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartService>();
    return Container(
      decoration: BoxDecoration(
        border:       Border.all(color: AppColors.line),
        borderRadius: const BorderRadius.all(kR4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          onTap: item.quantity > 1 ? () {
            HapticFeedback.lightImpact();
            cart.updateQuantity(item, item.quantity - 1);
          } : null,
          borderRadius: const BorderRadius.all(kR4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.remove, size: 14,
                color: item.quantity > 1 ? AppColors.ink : Colors.grey[300]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedSwitcher(
            duration:           const Duration(milliseconds: 150),
            transitionBuilder:  (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text('${item.quantity}',
              key:   ValueKey(item.quantity),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            cart.updateQuantity(item, item.quantity + 1);
          },
          borderRadius: const BorderRadius.all(kR4),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child:   Icon(Icons.add, size: 14, color: AppColors.ink),
          ),
        ),
      ]),
    );
  }
}

class _CartFooter extends StatelessWidget {
  final CartService cart;
  const _CartFooter({required this.cart});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    decoration: BoxDecoration(color: AppColors.card, boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.07),
          blurRadius: 12, offset: const Offset(0, -3)),
    ]),
    child: SafeArea(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Subtotal (${cart.itemCount} art.)',
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child:    Text(cart.formattedTotal,
                key:   ValueKey(cart.total),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
            ),
          ]),
          const Text('+ Envío GRATIS',
            style: TextStyle(color: AppColors.blue, fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        AppButton(
          label:           'Proceder al pago',
          backgroundColor: AppColors.yellow,
          icon:            Icons.lock_outline,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [BlocProvider.value(value: context.read<OrderBloc>())],
                child:     CheckoutScreen(cart: cart),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ]),
    ),
  );
}
