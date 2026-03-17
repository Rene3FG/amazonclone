import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../blocs/product/product_bloc.dart';
import '../blocs/wishlist/wishlist_bloc.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/shared_widgets.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl  = TextEditingController();
  bool  _isSearching = false;

  static const _catLabels = {
    "men's clothing":   'Hombre',
    "women's clothing": 'Mujer',
    'jewelery':         'Joyería',
    'electronics':      'Electrónica',
  };

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        titleSpacing: 12,
        title: _isSearching
            ? TextField(
                controller:  _searchCtrl,
                autofocus:   true,
                style:       const TextStyle(color: Colors.white),
                cursorColor: AppColors.orange,
                decoration: InputDecoration(
                  hintText:       'Buscar productos...',
                  hintStyle:      TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled:         false,
                  border:         InputBorder.none,
                  enabledBorder:  InputBorder.none,
                  focusedBorder:  InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (q) =>
                    context.read<ProductBloc>().add(SearchProducts(q)),
              )
            : const Text('amazon',
                style: TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchCtrl.clear();
                context.read<ProductBloc>().add(SearchProducts(''));
              }
            },
          ),
          CartBadge(
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading || state is ProductInitial) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.orange));
          }
          if (state is ProductError) {
            return ErrorBox(
              message: state.message,
              onRetry: () => context.read<ProductBloc>().add(LoadProducts()),
            );
          }
          if (state is ProductLoaded) {
            if (_isSearching && state.searchQuery.isNotEmpty) {
              return _SearchResults(products: state.displayedProducts);
            }
            return _HomeBody(state: state, catLabels: _catLabels);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<Product> products;
  const _SearchResults({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyState(
          icon: Icons.search_off, title: 'Sin resultados',
          subtitle: 'Prueba con otro término');
    }
    return ListView.builder(
      padding:     const EdgeInsets.all(10),
      itemCount:   products.length,
      itemBuilder: (context, i) => SlideIn(
        delay: Duration(milliseconds: i * 30),
        child: _SearchRow(product: products[i]),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final Product product;
  const _SearchRow({required this.product});

  @override
  Widget build(BuildContext context) => PressEffect(
    onTap: () => _push(context),
    child: Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.all(kR8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(children: [
        Container(
          width: 65, height: 65,
          color: Colors.grey[50], padding: const EdgeInsets.all(6),
          child: ProductImage(imageUrl: product.imageUrl, heroTag: 's-${product.id}'),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.title,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(height: 4),
          StarsWidget(value: product.rating, count: product.ratingCount),
          const SizedBox(height: 4),
          Row(children: [
            Text(product.formattedPrice,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (product.originalPrice != null) ...[
              const SizedBox(width: 6),
              Text(product.formattedOriginalPrice,
                style: const TextStyle(fontSize: 11, color: AppColors.muted,
                    decoration: TextDecoration.lineThrough)),
            ],
          ]),
        ])),
      ]),
    ),
  );

  void _push(BuildContext ctx) => Navigator.push(
    ctx, MaterialPageRoute(builder: (_) => DetailScreen(product: product)));
}

class _HomeBody extends StatefulWidget {
  final ProductLoaded       state;
  final Map<String, String> catLabels;
  const _HomeBody({required this.state, required this.catLabels});
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  int _bannerIndex = 0;
  final _bannerCtrl = PageController();

  static final _banners = [
    {'txt': 'Ofertas del día',   'sub': 'Hasta 23% de descuento',
     'bg': const Color(0xFF0071A2), 'ic': Icons.local_offer_outlined},
    {'txt': 'Envío GRATIS',      'sub': 'En todos tus pedidos',
     'bg': const Color(0xFF007600), 'ic': Icons.local_shipping_outlined},
    {'txt': 'Paga seguro',       'sub': 'Múltiples métodos de pago',
     'bg': const Color(0xFFC7511F), 'ic': Icons.security_outlined},
  ];

  @override
  void dispose() { _bannerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color:    AppColors.orange,
      onRefresh: () async {
        context.read<ProductBloc>().add(RefreshProducts());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        children: [
          
          _CatChips(state: widget.state, catLabels: widget.catLabels),

          _Banner(
            banners:      _banners,
            controller:   _bannerCtrl,
            currentIndex: _bannerIndex,
            onChanged:    (i) => setState(() => _bannerIndex = i),
          ),

          if (widget.state.deals.isNotEmpty) ...[
            _SectionHeader(title: '🔥 Ofertas del día', color: AppColors.deal),
            _HorizontalList(products: widget.state.deals,
                heroPrefix: 'deal', showDiscount: true),
          ],

          if (widget.state.topRated.isNotEmpty) ...[
            const _SectionHeader(title: '⭐ Mejor valorados'),
            _HorizontalList(products: widget.state.topRated, heroPrefix: 'top'),
          ],

          const _SectionHeader(title: 'Todos los productos'),
          _ProductGrid(products: widget.state.displayedProducts),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    child: Text(title,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
          color: color ?? AppColors.ink)),
  );
}

class _CatChips extends StatelessWidget {
  final ProductLoaded       state;
  final Map<String, String> catLabels;
  const _CatChips({required this.state, required this.catLabels});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        _Chip(label: 'Todo', isActive: state.activeCategory == null,
            onTap: () => context.read<ProductBloc>().add(const FilterByCategory(null))),
        ...state.categories.map((c) => _Chip(
          label:    catLabels[c] ?? c,
          isActive: state.activeCategory == c,
          onTap:    () => context.read<ProductBloc>().add(FilterByCategory(c)),
        )),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label; final bool isActive; final VoidCallback onTap;
  const _Chip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin:  const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color:  isActive ? AppColors.navy : Colors.white,
        borderRadius: const BorderRadius.all(kR99),
        border: Border.all(color: isActive ? AppColors.navy : AppColors.line),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: isActive ? Colors.white : AppColors.ink,
      )),
    ),
  );
}

class _Banner extends StatelessWidget {
  final List<Map<String, dynamic>> banners;
  final PageController             controller;
  final int                        currentIndex;
  final ValueChanged<int>          onChanged;
  const _Banner({required this.banners, required this.controller,
      required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(
      height: 110,
      child: PageView.builder(
        controller:    controller,
        onPageChanged: onChanged,
        itemCount:     banners.length,
        itemBuilder:   (_, i) {
          final b = banners[i];
          return Container(
            margin:     const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: b['bg'] as Color,
              borderRadius: const BorderRadius.all(kR12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:  MainAxisAlignment.center,
                children: [
                  Text(b['txt'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(b['sub'] as String,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              )),
              Icon(b['ic'] as IconData,
                  color: Colors.white.withOpacity(0.2), size: 52),
            ]),
          );
        },
      ),
    ),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(banners.length, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width:  currentIndex == i ? 18 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: currentIndex == i ? AppColors.orange : Colors.grey[300],
          borderRadius: const BorderRadius.all(kR99),
        ),
      )),
    ),
    const SizedBox(height: 4),
  ]);
}

class _HorizontalList extends StatelessWidget {
  final List<Product> products;
  final String        heroPrefix;
  final bool          showDiscount;
  const _HorizontalList({required this.products, required this.heroPrefix,
      this.showDiscount = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: showDiscount ? 220 : 210,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding:         const EdgeInsets.symmetric(horizontal: 12),
      itemCount:       products.length,
      itemBuilder:     (_, i) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child:   _SmallCard(product: products[i],
            width: 140, heroPrefix: heroPrefix, showDiscount: showDiscount),
      ),
    ),
  );
}

class _SmallCard extends StatelessWidget {
  final Product product;
  final double  width;
  final String  heroPrefix;
  final bool    showDiscount;
  const _SmallCard({required this.product, required this.width,
      required this.heroPrefix, this.showDiscount = false});

  @override
  Widget build(BuildContext context) => PressEffect(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => DetailScreen(product: product))),
    child: Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.all(kR8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: kR8),
            child: Container(
              height: showDiscount ? 110 : 120,
              color:  Colors.grey[50], padding: const EdgeInsets.all(8),
              child:  Center(child: ProductImage(
                  imageUrl: product.imageUrl, heroTag: '$heroPrefix-${product.id}')),
            ),
          ),
          if (showDiscount && product.discountPercent != null)
            Positioned(top: 6, left: 6,
                child: DiscountBadge(percent: product.discountPercent!)),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.ink, height: 1.3)),
            const SizedBox(height: 3),
            if (!showDiscount) StarsWidget(value: product.rating, size: 11),
            const SizedBox(height: 3),
            Text(product.formattedPrice,
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.bold, color: AppColors.ink)),
            if (showDiscount && product.originalPrice != null)
              Text(product.formattedOriginalPrice,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted,
                      decoration: TextDecoration.lineThrough)),
          ]),
        ),
      ]),
    ),
  );
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      
      final width     = constraints.maxWidth;
      final cols      = width > 900 ? 4 : width > 600 ? 3 : 2;
      final spacing   = 10.0;
      final padding   = 10.0;
      final cardWidth = (width - padding * 2 - spacing * (cols - 1)) / cols;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Wrap(
          spacing:     spacing,
          runSpacing:  spacing,
          children: List.generate(products.length, (i) => SlideIn(
            delay: Duration(milliseconds: (i % 6) * 40),
            child: SizedBox(
              width:  cardWidth,
              height: 260, 
              child:  _GridCard(product: products[i]),
            ),
          )),
        ),
      );
    });
  }
}

class _GridCard extends StatelessWidget {
  final Product product;
  const _GridCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart      = context.read<CartService>();
    final wishState = context.watch<WishlistBloc>().state;
    final isFav     = wishState is WishlistLoaded && wishState.contains(product.id);

    return PressEffect(
      onTap: () => Navigator.push(context,
        PageRouteBuilder(
          pageBuilder:        (_, __, ___) => DetailScreen(product: product),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 230),
        )),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.all(kR8),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 5,
              offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: kR8),
              child: Container(
                height: 140, width: double.infinity,
                color:  Colors.grey[50], padding: const EdgeInsets.all(10),
                child:  Center(child: ProductImage(
                    imageUrl: product.imageUrl, heroTag: '${product.id}')),
              ),
            ),
            if (product.hasDiscount)
              Positioned(top: 6, left: 6,
                  child: DiscountBadge(percent: product.discountPercent!)),
            Positioned(top: 6, right: 6,
              child: WishlistButton(
                productId:  product.id,
                isFavorite: isFav,
                onToggle:   () => context.read<WishlistBloc>()
                    .add(ToggleWishlist(product.id)),
              ),
            ),
          ]),

          SizedBox(
            height:  120,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.ink, height: 1.3)),
                  const SizedBox(height: 4),
                  StarsWidget(value: product.rating,
                      count: product.ratingCount, size: 11),
                  const Spacer(),
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.formattedPrice,
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.bold, color: AppColors.ink)),
                        if (product.originalPrice != null)
                          Text(product.formattedOriginalPrice,
                            style: const TextStyle(fontSize: 10,
                                color: AppColors.muted,
                                decoration: TextDecoration.lineThrough)),
                      ],
                    )),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        cart.addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Agregado al carrito'),
                            duration: Duration(seconds: 1),
                            backgroundColor: AppColors.green),
                        );
                      },
                      child: Container(
                        padding:    const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                            color: AppColors.yellow, shape: BoxShape.circle),
                        child: const Icon(Icons.add_shopping_cart,
                            size: 14, color: AppColors.ink),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
