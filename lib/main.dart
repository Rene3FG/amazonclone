import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/order/order_bloc.dart';
import 'blocs/product/product_bloc.dart';
import 'blocs/review/review_bloc.dart';
import 'blocs/wishlist/wishlist_bloc.dart';
import 'core/theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/review_repository.dart';
import 'repositories/wishlist_repository.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'services/cart_service.dart';
import 'widgets/shared_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Supabase.initialize(
    url: 'https://naiwccpffldjpvcohidp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5haXdjY3BmZmxkanB2Y29oaWRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4ODAzODIsImV4cCI6MjA4NzQ1NjM4Mn0.S64yoFU8_IgYSZBjKPpWBVeF8hYoFffR0QVhQCe2J68',
  );
  final authRepo    = AuthRepository();
  final productRepo = ProductRepository();
  final orderRepo   = OrderRepository();
  final reviewRepo  = ReviewRepository();
  final wishRepo    = WishlistRepository();
  final cartService = CartService();
  runApp(AmazonApp(
    authRepo: authRepo, productRepo: productRepo, orderRepo: orderRepo,
    reviewRepo: reviewRepo, wishRepo: wishRepo, cartService: cartService,
  ));
}

class AmazonApp extends StatelessWidget {
  final AuthRepository authRepo;
  final ProductRepository productRepo;
  final OrderRepository orderRepo;
  final ReviewRepository reviewRepo;
  final WishlistRepository wishRepo;
  final CartService cartService;

  const AmazonApp({
    super.key,
    required this.authRepo, required this.productRepo, required this.orderRepo,
    required this.reviewRepo, required this.wishRepo, required this.cartService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cartService),
        BlocProvider(create: (_) => AuthBloc(authRepo)),
        BlocProvider(create: (_) => ProductBloc(productRepo)),
        BlocProvider(create: (_) => OrderBloc(orderRepo, productRepo, authRepo)),
        BlocProvider(create: (_) => ReviewBloc(reviewRepo, authRepo)),
        BlocProvider(create: (_) => WishlistBloc(wishRepo, authRepo)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Amazon 2026',
        theme: buildAppTheme(),
        home: const AppRoot(),

      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CheckSession());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AppAuthState>(
      listener: (ctx, state) {
        if (state is AppAuthAuthenticated) {
          ctx.read<CartService>().initialize(state.userId);
          ctx.read<OrderBloc>().add(LoadOrders());
          ctx.read<ProductBloc>().add(LoadProducts());
          ctx.read<WishlistBloc>().add(LoadWishlist());
        }
        if (state is AppAuthUnauthenticated) {
          ctx.read<CartService>().reset();
        }
      },
      builder: (ctx, state) {
        if (state is AppAuthInitial || state is AppAuthLoading) {
          return const Scaffold(
            backgroundColor: AppColors.navy,
            body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
          );
        }
        if (state is AppAuthAuthenticated) return const AppShell();
        return const LoginScreen();
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  static const _screens = [
    HomeScreen(), CartScreen(), OrdersScreen(), ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _tab, children: _screens),
    bottomNavigationBar: Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2)),
      ]),
      child: BottomNavigationBar(
        currentIndex: _tab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.muted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        onTap: (i) { HapticFeedback.selectionClick(); setState(() => _tab = i); },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: CartBadge(child: const Icon(Icons.shopping_cart_outlined)),
            activeIcon: CartBadge(child: const Icon(Icons.shopping_cart)),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Pedidos'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    ),
  );
}
