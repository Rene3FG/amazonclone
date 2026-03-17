import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../blocs/review/review_bloc.dart';
import '../blocs/wishlist/wishlist_bloc.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../services/cart_service.dart';
import '../widgets/shared_widgets.dart';

class DetailScreen extends StatefulWidget {
  final Product product;
  const DetailScreen({super.key, required this.product});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    context.read<ReviewBloc>().add(LoadReviews(widget.product.id));
  }

  @override
  Widget build(BuildContext context) {
    final wishState = context.watch<WishlistBloc>().state;
    final isFav     = wishState is WishlistLoaded && wishState.contains(widget.product.id);
    final p         = widget.product;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(p.category,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          WishlistButton(
            productId:  p.id,
            isFavorite: isFav,
            onToggle:   () => context.read<WishlistBloc>()
                .add(ToggleWishlist(p.id)),
          ),
          const SizedBox(width: 4),
          CartBadge(
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _ProductHero(product: p)),
        SliverToBoxAdapter(child: _ProductInfo(
          product: p,
          qty:     _qty,
          onQtyChanged: (q) => setState(() => _qty = q),
        )),
        SliverToBoxAdapter(child: _ReviewsSection(product: p)),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
      bottomNavigationBar: _AddToCartBar(product: p, qty: _qty),
    );
  }
}

class _ProductHero extends StatelessWidget {
  final Product product;
  const _ProductHero({required this.product});

  @override
  Widget build(BuildContext context) => Container(
    color:   Colors.white,
    padding: const EdgeInsets.all(20),
    child:   SizedBox(
      height: 280,
      child:  ProductImage(
        imageUrl: product.imageUrl,
        heroTag:  '${product.id}',
        height:   260,
      ),
    ),
  );
}

class _ProductInfo extends StatelessWidget {
  final Product product;
  final int     qty;
  final ValueChanged<int> onQtyChanged;
  const _ProductInfo({required this.product, required this.qty, required this.onQtyChanged});

  @override
  Widget build(BuildContext context) => Container(
    color:   Colors.white,
    margin:  const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(16),
    child:   Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      
      Container(
        padding:    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        AppColors.blue.withOpacity(0.1),
          borderRadius: const BorderRadius.all(kR99),
        ),
        child: Text(product.category,
          style: const TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w500)),
      ),
      const SizedBox(height: 8),

      Text(product.title,
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.3)),
      const SizedBox(height: 10),

      Row(children: [
        StarsWidget(value: product.rating, count: product.ratingCount, size: 14),
        const Spacer(),
        const Icon(Icons.verified_outlined, size: 14, color: AppColors.green),
        const SizedBox(width: 4),
        const Text('En stock',
          style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 12),

      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
        children: [
          Text(product.formattedPrice,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.ink)),
          if (product.originalPrice != null) ...[
            const SizedBox(width: 8),
            Text(product.formattedOriginalPrice,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.muted,
                  decoration: TextDecoration.lineThrough)),
            const SizedBox(width: 6),
            if (product.discountPercent != null)
              DiscountBadge(percent: product.discountPercent!),
          ],
        ],
      ),
      const SizedBox(height: 4),
      const Row(children: [
        Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.blue),
        SizedBox(width: 4),
        Text('Envío GRATIS',
          style: TextStyle(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 14),

      Row(children: [
        const Text('Cantidad:', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(width: 10),
        _QuantitySelector(qty: qty, onChanged: onQtyChanged),
      ]),
      const SizedBox(height: 16),

      const Text('Descripción',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
      const SizedBox(height: 6),
      Text(product.description,
        style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6)),
    ]),
  );
}

class _QuantitySelector extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  const _QuantitySelector({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        border:       Border.all(color: AppColors.line),
        borderRadius: const BorderRadius.all(kR4)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: qty > 1 ? () {
          HapticFeedback.selectionClick();
          onChanged(qty - 1);
        } : null,
        borderRadius: const BorderRadius.all(kR4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.remove, size: 14,
              color: qty > 1 ? AppColors.ink : Colors.grey[300]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child:    Text('$qty',
            key:   ValueKey(qty),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
      InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(qty + 1);
        },
        borderRadius: const BorderRadius.all(kR4),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child:   Icon(Icons.add, size: 14, color: AppColors.ink),
        ),
      ),
    ]),
  );
}

class _AddToCartBar extends StatelessWidget {
  final Product product;
  final int     qty;
  const _AddToCartBar({required this.product, required this.qty});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    decoration: BoxDecoration(color: AppColors.card, boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.07),
          blurRadius: 12, offset: const Offset(0, -3)),
    ]),
    child: SafeArea(
      child: Row(children: [
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon:  const Icon(Icons.bolt_outlined, size: 16),
            label: const Text('Comprar ya'),
            style: OutlinedButton.styleFrom(
              side:    const BorderSide(color: AppColors.orange),
              foregroundColor: AppColors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape:   const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(kR8)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.read<CartService>().addItem(product, quantity: qty);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${product.title.substring(0, 20)}... agregado'),
                backgroundColor: AppColors.green,
                duration: const Duration(seconds: 2),
              ));
            },
            icon:  const Icon(Icons.shopping_cart_outlined, size: 16),
            label: const Text('Agregar al carrito'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ]),
    ),
  );
}

class _ReviewsSection extends StatelessWidget {
  final Product product;
  const _ReviewsSection({required this.product});

  @override
  Widget build(BuildContext context) => Container(
    color:   Colors.white,
    margin:  const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(16),
    child: BlocBuilder<ReviewBloc, ReviewState>(
      builder: (context, state) {
        if (state is ReviewLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child:   CircularProgressIndicator(color: AppColors.orange),
          ));
        }
        if (state is ReviewLoaded) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Reseñas',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (state.reviews.isNotEmpty) ...[
                StarsWidget(value: state.averageRating, size: 14),
                const SizedBox(width: 6),
                Text('${state.averageRating.toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ]),
            const SizedBox(height: 12),

            if (!state.userHasReviewed)
              _WriteReviewForm(productId: product.id),

            if (state.reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child:   Center(child: Text('Sé el primero en reseñar este producto',
                    style: TextStyle(color: AppColors.muted, fontSize: 13))),
              )
            else
              ...state.reviews.map((r) => _ReviewCard(
                review:   r,
                myUserId: context.read<ReviewBloc>().state is ReviewLoaded
                    ? null
                    : null,
                productId: product.id,
              )),
          ]);
        }
        return const SizedBox.shrink();
      },
    ),
  );
}

class _WriteReviewForm extends StatefulWidget {
  final int productId;
  const _WriteReviewForm({required this.productId});
  @override
  State<_WriteReviewForm> createState() => _WriteReviewFormState();
}

class _WriteReviewFormState extends State<_WriteReviewForm> {
  final _commentCtrl = TextEditingController();
  double _rating     = 5;
  bool   _expanded   = false;

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: Container(
          padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:        AppColors.bg,
            borderRadius: const BorderRadius.all(kR8),
            border:       Border.all(color: AppColors.line),
          ),
          child: Row(children: const [
            Icon(Icons.rate_review_outlined, size: 16, color: AppColors.muted),
            SizedBox(width: 8),
            Text('Escribe una reseña...', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ]),
        ),
      );
    }

    return Container(
      padding:    const EdgeInsets.all(14),
      margin:     const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        AppColors.bg,
        borderRadius: const BorderRadius.all(kR8),
        border:       Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tu calificación:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(children: List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() => _rating = i + 1.0),
          child: Icon(
            i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 28, color: const Color(0xFFFF8F00),
          ),
        ))),
        const SizedBox(height: 10),
        TextField(
          controller: _commentCtrl,
          maxLines:   3,
          decoration: const InputDecoration(
            hintText: 'Comparte tu opinión...',
            border:   OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            onPressed: () => setState(() { _expanded = false; _commentCtrl.clear(); }),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (_commentCtrl.text.trim().isEmpty) return;
              context.read<ReviewBloc>().add(PostReview(
                productId: widget.productId,
                rating:    _rating,
                comment:   _commentCtrl.text.trim(),
              ));
              setState(() { _expanded = false; _commentCtrl.clear(); });
            },
            child: const Text('Publicar'),
          ),
        ]),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final String? myUserId;
  final int productId;
  const _ReviewCard({required this.review, this.myUserId, required this.productId});

  @override
  Widget build(BuildContext context) => Container(
    margin:  const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        AppColors.bg,
      borderRadius: const BorderRadius.all(kR8),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(
          radius:          16,
          backgroundColor: AppColors.navy,
          child:           Text(review.initials,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(review.userEmail.split('@')[0],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(review.formattedDate,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
        StarsWidget(value: review.rating, size: 12),
        if (myUserId == review.userId)
          IconButton(
            icon:    const Icon(Icons.delete_outline, size: 16, color: AppColors.muted),
            onPressed: () => context.read<ReviewBloc>()
                .add(DeleteReview(review.id, productId)),
          ),
      ]),
      const SizedBox(height: 8),
      Text(review.comment,
        style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.5)),
    ]),
  );
}
