import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/order/order_bloc.dart';
import '../blocs/product/product_bloc.dart';
import '../blocs/review/review_bloc.dart';
import '../blocs/wishlist/wishlist_bloc.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../services/cart_service.dart';
import '../widgets/shared_widgets.dart';
import 'detail_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: BlocBuilder<AuthBloc, AppAuthState>(
        builder: (context, authState) {
          final email    = authState is AppAuthAuthenticated ? authState.email : null;
          final userId   = authState is AppAuthAuthenticated ? authState.userId : '';
          final initials = _getInitials(email);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SlideIn(child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: const BorderRadius.all(kR12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.navy,
                    child: Text(initials,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(email?.split('@')[0] ?? 'Usuario',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(email ?? '', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.prime.withOpacity(0.1),
                        borderRadius: const BorderRadius.all(kR99),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star, size: 11, color: AppColors.prime),
                        SizedBox(width: 3),
                        Text('Prime', style: TextStyle(fontSize: 11, color: AppColors.prime, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ])),
                ]),
              )),
              const SizedBox(height: 20),

              _ProfileSection(title: 'COMPRAS', tiles: [
                _ProfileTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Mis pedidos',
                  subtitle: 'Rastrea y gestiona tus compras',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<OrderBloc>(),
                      child: const _AllOrdersPage(),
                    ),
                  )),
                ),
                _ProfileTile(
                  icon: Icons.favorite_outline,
                  label: 'Lista de deseos',
                  subtitle: 'Productos guardados',
                  onTap: () {
                    final wishBloc    = context.read<WishlistBloc>();
                    final productBloc = context.read<ProductBloc>();
                    final cart        = context.read<CartService>();
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: wishBloc),
                          BlocProvider.value(value: productBloc),
                        ],
                        child: ChangeNotifierProvider.value(
                          value: cart,
                          child: const _WishlistPage(),
                        ),
                      ),
                    ));
                  },
                ),
                _ProfileTile(
                  icon: Icons.star_border_outlined,
                  label: 'Mis reseñas',
                  subtitle: 'Opiniones que has publicado',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _MyReviewsPage(userId: userId),
                  )),
                ),
              ]),
              const SizedBox(height: 14),

              _ProfileSection(title: 'CUENTA', tiles: [
                _ProfileTile(
                  icon: Icons.location_on_outlined,
                  label: 'Mis direcciones',
                  subtitle: 'Gestiona tus direcciones de entrega',
                  onTap: () => _showAddressDialog(context),
                ),
                _ProfileTile(
                  icon: Icons.credit_card_outlined,
                  label: 'Métodos de pago',
                  subtitle: 'Tarjetas guardadas',
                  onTap: () => _showPaymentDialog(context),
                ),
                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notificaciones',
                  subtitle: 'Configurar alertas y avisos',
                  onTap: () => showDialog(context: context, builder: (_) => const _NotificationsDialog()),
                ),
              ]),
              const SizedBox(height: 14),

              _ProfileSection(title: 'SOPORTE', tiles: [
                _ProfileTile(
                  icon: Icons.help_outline,
                  label: 'Ayuda y soporte',
                  subtitle: 'Preguntas frecuentes',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _HelpPage())),
                ),
                _ProfileTile(
                  icon: Icons.info_outline,
                  label: 'Acerca de',
                  subtitle: 'Amazon 2026 v1.0',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AboutPage())),
                ),
              ]),
              const SizedBox(height: 14),

              SlideIn(
                delay: const Duration(milliseconds: 200),
                child: AppButton(
                  label: 'Cerrar sesión',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.danger,
                  icon: Icons.logout,
                  onTap: () => _confirmLogout(context),
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  String _getInitials(String? email) {
    if (email == null) return 'U';
    final parts = email.split('@')[0].split('.');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : email[0].toUpperCase();
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('¿Cerrar sesión?'),
        content: const Text('Tendrás que volver a iniciar sesión.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Mis direcciones'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _AddressTile(icon: Icons.home_outlined,  label: 'Casa',    address: 'Calle Principal 123, CDMX'),
        _AddressTile(icon: Icons.work_outlined,  label: 'Trabajo', address: 'Av. Reforma 456, CDMX'),
        const Divider(),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Agregar dirección'),
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    ),
  );

  void _showPaymentDialog(BuildContext context) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Métodos de pago'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(
          dense: true,
          leading: Icon(Icons.credit_card_outlined, color: AppColors.muted),
          title: Text('No hay tarjetas guardadas', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        ),
        const Divider(),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Agregar tarjeta'),
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    ),
  );
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileTile> tiles;
  const _ProfileSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Text(title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6)),
    ),
    Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: const BorderRadius.all(kR8)),
      child: Column(children: tiles.asMap().entries.map((e) => Column(children: [
        e.value,
        if (e.key < tiles.length - 1) const Divider(height: 1, indent: 52),
      ])).toList()),
    ),
  ]);
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback? onTap;
  const _ProfileTile({required this.icon, required this.label, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(kR8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.navy.withOpacity(0.07),
              borderRadius: const BorderRadius.all(kR8),
            ),
            child: Icon(icon, color: AppColors.navy, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.ink)),
            const SizedBox(height: 1),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ]),
      ),
    ),
  );
}

class _AddressTile extends StatelessWidget {
  final IconData icon;
  final String label, address;
  const _AddressTile({required this.icon, required this.label, required this.address});

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(icon, color: AppColors.blue, size: 20),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    subtitle: Text(address, style: const TextStyle(fontSize: 12)),
  );
}

class _NotificationsDialog extends StatefulWidget {
  const _NotificationsDialog();
  @override
  State<_NotificationsDialog> createState() => _NotifState();
}

class _NotifState extends State<_NotificationsDialog> {
  bool _pedidos   = true;
  bool _ofertas   = true;
  bool _resenas   = false;
  bool _novedades = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Notificaciones'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      SwitchListTile(dense: true, activeColor: AppColors.orange,
        title: const Text('Estado de pedidos', style: TextStyle(fontSize: 14)),
        value: _pedidos, onChanged: (v) => setState(() => _pedidos = v)),
      SwitchListTile(dense: true, activeColor: AppColors.orange,
        title: const Text('Ofertas y descuentos', style: TextStyle(fontSize: 14)),
        value: _ofertas, onChanged: (v) => setState(() => _ofertas = v)),
      SwitchListTile(dense: true, activeColor: AppColors.orange,
        title: const Text('Respuestas a reseñas', style: TextStyle(fontSize: 14)),
        value: _resenas, onChanged: (v) => setState(() => _resenas = v)),
      SwitchListTile(dense: true, activeColor: AppColors.orange,
        title: const Text('Nuevos productos', style: TextStyle(fontSize: 14)),
        value: _novedades, onChanged: (v) => setState(() => _novedades = v)),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preferencias guardadas'), backgroundColor: AppColors.green));
          Navigator.pop(context);
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}

class _WishlistPage extends StatelessWidget {
  const _WishlistPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Lista de deseos')),
      body: BlocBuilder<WishlistBloc, WishlistState>(
        builder: (context, wishState) {
          if (wishState is! WishlistLoaded || wishState.productIds.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'Sin productos guardados',
              subtitle: 'Toca el ícono de corazón en cualquier producto para guardarlo aquí',
            );
          }
          return BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
              if (productState is! ProductLoaded) {
                return const Center(child: CircularProgressIndicator(color: AppColors.orange));
              }
              final products = productState.allProducts
                  .where((p) => wishState.productIds.contains(p.id))
                  .toList();
              if (products.isEmpty) {
                return const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'Sin productos guardados',
                  subtitle: 'Toca el ícono de corazón en cualquier producto para guardarlo aquí',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (context, i) => SlideIn(
                  delay: Duration(milliseconds: i * 40),
                  child: _WishlistCard(product: products[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final Product product;
  const _WishlistCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartService>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.all(kR8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(children: [
        PressEffect(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => DetailScreen(product: product))),
          child: Container(
            width: 70, height: 70,
            color: Colors.grey[50], padding: const EdgeInsets.all(6),
            child: ProductImage(imageUrl: product.imageUrl, heroTag: 'w-${product.id}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(height: 4),
          StarsWidget(value: product.rating, count: product.ratingCount, size: 11),
          const SizedBox(height: 4),
          Row(children: [
            Text(product.formattedPrice,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
            if (product.originalPrice != null) ...[
              const SizedBox(width: 6),
              Text(product.formattedOriginalPrice,
                style: const TextStyle(fontSize: 11, color: AppColors.muted,
                    decoration: TextDecoration.lineThrough)),
            ],
          ]),
        ])),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: () => context.read<WishlistBloc>().add(ToggleWishlist(product.id)),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, size: 18, color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              cart.addItem(product);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Producto agregado al carrito'),
                duration: Duration(seconds: 1),
                backgroundColor: AppColors.green,
              ));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
              child: const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.ink),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _MyReviewsPage extends StatefulWidget {
  final String userId;
  const _MyReviewsPage({required this.userId});
  @override
  State<_MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<_MyReviewsPage> {
  List<Review> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await Supabase.instance.client
          .from('reviews')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);
      final reviews = (rows as List)
          .map((r) => Review.fromRow(r as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _reviews = reviews; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: const Text('Mis reseñas')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
        : _reviews.isEmpty
            ? const EmptyState(
                icon: Icons.star_border_outlined,
                title: 'Sin reseñas todavía',
                subtitle: 'Realiza una compra y comparte tu opinión sobre el producto',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _reviews.length,
                itemBuilder: (context, i) => SlideIn(
                  delay: Duration(milliseconds: i * 40),
                  child: _ReviewCard(review: _reviews[i]),
                ),
              ),
  );
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: const BorderRadius.all(kR8),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: const BorderRadius.all(kR4),
            border: Border.all(color: AppColors.line),
          ),
          child: Text('Producto #${review.productId}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ),
        const Spacer(),
        StarsWidget(value: review.rating, size: 13),
      ]),
      const SizedBox(height: 8),
      Text(review.comment,
        style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.5)),
      const SizedBox(height: 6),
      Text(review.formattedDate,
        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    ]),
  );
}

class _HelpPage extends StatelessWidget {
  const _HelpPage();

  static final _faqs = [
    _FaqData('¿Cómo puedo rastrear mi pedido?',
        'Diríjase a "Mis pedidos" en su perfil. Allí encontrará el estado actualizado de cada compra: Procesando, En camino o Entregado.'),
    _FaqData('¿Puedo modificar o cancelar un pedido?',
        'Solo es posible cancelar pedidos en estado "Procesando". Una vez despachado, no es posible realizar cancelaciones. Contacte a soporte para más información.'),
    _FaqData('¿Cómo solicito una devolución?',
        'Dispone de 30 días desde la fecha de entrega para solicitar una devolución. Acceda al pedido correspondiente y seleccione "Solicitar devolución".'),
    _FaqData('¿Cómo funciona el envío gratuito?',
        'Todos los pedidos incluyen envío gratuito sin monto mínimo de compra. El tiempo de entrega estimado es de 3 a 5 días hábiles.'),
    _FaqData('¿Es seguro realizar pagos con tarjeta?',
        'Sí. Todos los pagos se procesan con encriptación SSL. En ningún caso se almacena el código de seguridad (CVV) de su tarjeta.'),
    _FaqData('¿Cómo publico una reseña?',
        'Abra el detalle de cualquier producto. Al desplazarse hacia abajo encontrará la sección de reseñas donde podrá publicar su opinión.'),
    _FaqData('¿Qué beneficios incluye Amazon Prime?',
        'Prime es el programa de membresía premium. Incluye despacho prioritario, acceso a ofertas exclusivas y contenido digital adicional.'),
    _FaqData('¿Cómo me comunico con soporte?',
        'Puede escribirnos a soporte@amazon2026.com o utilizar el chat en vivo disponible en esta misma sección, de lunes a viernes de 8:00 a 20:00 horas.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: const Text('Ayuda y soporte')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.all(kR12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('¿En qué podemos ayudarle?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Atención disponible las 24 horas, los 7 días de la semana',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            const SizedBox(height: 14),
            Row(children: [
              _ContactButton(
                icon: Icons.chat_outlined,
                label: 'Chat en vivo',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conectando con un agente...'))),
              ),
              const SizedBox(width: 10),
              _ContactButton(
                icon: Icons.email_outlined,
                label: 'Correo electrónico',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('soporte@amazon2026.com'))),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Preguntas frecuentes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
        ),
        ...List.generate(_faqs.length, (i) => SlideIn(
          delay: Duration(milliseconds: i * 40),
          child: _FaqItem(data: _faqs[i]),
        )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.all(kR8),
            border: Border.all(color: AppColors.line),
          ),
          child: const Row(children: [
            Icon(Icons.phone_outlined, color: AppColors.blue, size: 20),
            SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Línea de atención telefónica',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('800 123 4567 · Lunes a viernes, 8:00 – 20:00',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ]),
        ),
        const SizedBox(height: 30),
      ],
    ),
  );
}

class _FaqData {
  final String question;
  final String answer;
  const _FaqData(this.question, this.answer);
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: const BorderRadius.all(kR8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    ),
  );
}

class _FaqItem extends StatefulWidget {
  final _FaqData data;
  const _FaqItem({required this.data});
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: const BorderRadius.all(kR8),
      border: Border.all(color: _open ? AppColors.orange.withOpacity(0.4) : AppColors.line),
    ),
    child: Column(children: [
      ListTile(
        dense: true,
        title: Text(widget.data.question,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: _open ? AppColors.orange : AppColors.ink)),
        trailing: AnimatedRotation(
          turns: _open ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(Icons.keyboard_arrow_down, color: _open ? AppColors.orange : AppColors.muted),
        ),
        onTap: () => setState(() => _open = !_open),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Text(widget.data.answer,
            style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6)),
        ),
        crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ]),
  );
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: const Text('Acerca de')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SlideIn(child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: const BorderRadius.all(kR12),
          ),
          child: Column(children: [
            const Text('amazon',
              style: TextStyle(color: Colors.white, fontSize: 42,
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.2),
                borderRadius: const BorderRadius.all(kR99),
              ),
              child: const Text('Versión 1.0.0',
                style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ]),
        )),
        const SizedBox(height: 20),
        _AboutCard(icon: Icons.code_outlined,     label: 'Tecnología principal', value: 'Flutter · BLoC · Supabase'),
        _AboutCard(icon: Icons.storage_outlined,  label: 'Base de datos',        value: 'Supabase (PostgreSQL)'),
        _AboutCard(icon: Icons.api_outlined,      label: 'API de productos',      value: 'FakeStore API'),
        _AboutCard(icon: Icons.verified_outlined, label: 'Autenticación',         value: 'Supabase Auth + Google Sign-In'),
        _AboutCard(icon: Icons.update_outlined,   label: 'Última actualización',  value: '17 de marzo de 2026'),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Stack tecnológico',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: const [
          _TechBadge('Flutter',      AppColors.blue),
          _TechBadge('Dart',         Color(0xFF00B4D8)),
          _TechBadge('BLoC',         Color(0xFF7B2D8B)),
          _TechBadge('Supabase',     Color(0xFF3ECF8E)),
          _TechBadge('PostgreSQL',   Color(0xFF336791)),
          _TechBadge('Google Auth',  Color(0xFFEA4335)),
          _TechBadge('REST API',     AppColors.orange),
          _TechBadge('Material 3',   AppColors.navy),
        ]),
        const SizedBox(height: 24),
        const Center(child: Text('© 2026 Amazon 2026. Proyecto académico.',
          style: TextStyle(fontSize: 12, color: AppColors.muted))),
        const SizedBox(height: 16),
      ],
    ),
  );
}

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _AboutCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: const BorderRadius.all(kR8),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(children: [
      Icon(icon, color: AppColors.blue, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
      ])),
    ]),
  );
}

class _TechBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TechBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: const BorderRadius.all(kR99),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label,
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  );
}

class _AllOrdersPage extends StatefulWidget {
  const _AllOrdersPage();
  @override
  State<_AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<_AllOrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(LoadOrders());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: const Text('Mis pedidos'), actions: [
      IconButton(
        icon: const Icon(Icons.refresh_outlined, color: Colors.white),
        onPressed: () => context.read<OrderBloc>().add(LoadOrders()),
      ),
    ]),
    body: BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading || state is OrderInitial) {
          return const Center(child: CircularProgressIndicator(color: AppColors.orange));
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
              icon: Icons.receipt_long_outlined,
              title: 'Sin pedidos todavía',
              subtitle: 'Sus compras aparecerán aquí una vez realizadas',
            );
          }
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: () async {
              context.read<OrderBloc>().add(LoadOrders());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: state.orders.length,
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
