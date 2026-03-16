import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';

const _kBase = 'https://fakestoreapi.com';
const _kMs = 500;

abstract class C {
  static const navy = Color(0xFF131921);
  static const blue = Color(0xFF0071A2);
  static const orange = Color(0xFFFF9900);
  static const yellow = Color(0xFFFFD814);
  static const bg = Color(0xFFF0F2F2);
  static const green = Color(0xFF007600);
  static const danger = Color(0xFFCC0C39);
  static const ink = Color(0xFF0F1111);
  static const muted = Color(0xFF565959);
  static const line = Color(0xFFDDDDDD);
  static const deal = Color(0xFFC7511F);
  static const prime = Color(0xFF00A8E1);
  static const card = Colors.white;
}

const r4 = Radius.circular(4);
const r8 = Radius.circular(8);
const r12 = Radius.circular(12);
const r99 = Radius.circular(99);

ThemeData get appTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: C.blue),
      scaffoldBackgroundColor: C.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: C.navy,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.yellow,
          foregroundColor: C.ink,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          shape:
              const RoundedRectangleBorder(borderRadius: BorderRadius.all(r8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(r4),
            borderSide: const BorderSide(color: C.line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(r4),
            borderSide: const BorderSide(color: C.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(r4),
            borderSide: const BorderSide(color: C.orange, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(r4),
            borderSide: const BorderSide(color: C.danger)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: C.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(r8)),
      ),
    );

// ── Exceptions ────────────────────────────────────────────────
class AppEx implements Exception {
  final String msg;
  const AppEx(this.msg);
  @override
  String toString() => msg;
}

class AuthEx extends AppEx {
  const AuthEx(super.m);
}

class NetEx extends AppEx {
  const NetEx(super.m);
}

class CartEx extends AppEx {
  const CartEx(super.m);
}

class OrderEx extends AppEx {
  const OrderEx(super.m);
}

class RevEx extends AppEx {
  const RevEx(super.m);
}

// ── Models ────────────────────────────────────────────────────
class Product extends Equatable {
  final int id;
  final String title, description, category, image;
  final double price;
  final double? rating;
  final int? ratingCount;
  final double? origPrice;
  final int? discount;

  const Product(
      {required this.id,
      required this.title,
      required this.description,
      required this.category,
      required this.image,
      required this.price,
      this.rating,
      this.ratingCount,
      this.origPrice,
      this.discount});

  factory Product.fromJson(Map<String, dynamic> j) {
    final price = (j['price'] as num).toDouble();
    final isDeal = (j['id'] as int) % 3 == 0;
    return Product(
      id: j['id'] as int,
      title: j['title'] as String,
      description: j['description'] as String,
      category: j['category'] as String,
      image: j['image'] as String,
      price: price,
      rating: (j['rating']?['rate'] as num?)?.toDouble(),
      ratingCount: j['rating']?['count'] as int?,
      origPrice: isDeal ? double.parse((price * 1.3).toStringAsFixed(2)) : null,
      discount: isDeal ? 23 : null,
    );
  }

  String get dp => '\$${price.toStringAsFixed(2)}';
  String get op => '\$${origPrice?.toStringAsFixed(2) ?? ''}';
  bool get hasOffer => discount != null;
  @override
  List<Object?> get props => [id, price, title];
}

class CartItem extends Equatable {
  final String id;
  final Product product;
  final int qty;
  const CartItem({required this.id, required this.product, required this.qty});
  double get sub => product.price * qty;
  String get dsub => '\$${sub.toStringAsFixed(2)}';
  CartItem wq(int q) => CartItem(id: id, product: product, qty: q);
  @override
  List<Object?> get props => [id, product.id, qty];
}

class OItem extends Equatable {
  final Product product;
  final int qty;
  final double price;
  const OItem({required this.product, required this.qty, required this.price});
  @override
  List<Object?> get props => [product.id, qty];
}

enum OStatus { processing, shipped, delivered, cancelled }

extension OStatusX on OStatus {
  String get label => switch (this) {
        OStatus.processing => 'Procesando',
        OStatus.shipped => 'En camino',
        OStatus.delivered => 'Entregado',
        OStatus.cancelled => 'Cancelado'
      };
  Color get color => switch (this) {
        OStatus.processing => C.orange,
        OStatus.shipped => C.blue,
        OStatus.delivered => C.green,
        OStatus.cancelled => C.danger
      };
  IconData get icon => switch (this) {
        OStatus.processing => Icons.inventory_2_outlined,
        OStatus.shipped => Icons.local_shipping_outlined,
        OStatus.delivered => Icons.check_circle_outline,
        OStatus.cancelled => Icons.cancel_outlined
      };
}

class Order extends Equatable {
  final String id;
  final DateTime at;
  final double total;
  final List<OItem> items;
  final OStatus status;

  const Order(
      {required this.id,
      required this.at,
      required this.total,
      required this.items,
      this.status = OStatus.processing});

  String get sid {
    final s = id.replaceAll('-', '');
    return '#${s.substring(0, s.length.clamp(0, 8)).toUpperCase()}';
  }

  String get fdate => DateFormat('d MMM yyyy', 'es').format(at);
  String get dtotal => '\$${total.toStringAsFixed(2)}';

  factory Order.fromRow(Map<String, dynamic> r, List<OItem> items) => Order(
        id: r['id'].toString(),
        at: DateTime.parse(r['created_at'] as String),
        total: (r['total_amount'] as num).toDouble(),
        items: items,
        status: OStatus.values[(r['status'] as int?) ?? 0],
      );
  @override
  List<Object?> get props => [id, at, total, status];
}

class SavedCard extends Equatable {
  final String last4, brand, holder, expiry;
  const SavedCard(
      {required this.last4,
      required this.brand,
      required this.holder,
      required this.expiry});
  @override
  List<Object?> get props => [last4, brand];
}

class ShippingAddress extends Equatable {
  final String name, street, city, zip, country;
  const ShippingAddress(
      {required this.name,
      required this.street,
      required this.city,
      required this.zip,
      required this.country});
  String get full => '$street, $city $zip, $country';
  @override
  List<Object?> get props => [street, city];
}

class Review extends Equatable {
  final String id, userId, userEmail, comment;
  final int productId;
  final double rating;
  final DateTime at;

  const Review(
      {required this.id,
      required this.userId,
      required this.userEmail,
      required this.productId,
      required this.rating,
      required this.comment,
      required this.at});

  factory Review.fromRow(Map<String, dynamic> r) => Review(
        id: r['id'].toString(),
        userId: r['user_id'] as String,
        userEmail: r['user_email'] as String? ?? 'Usuario',
        productId: r['product_id'] as int,
        rating: (r['rating'] as num).toDouble(),
        comment: r['comment'] as String,
        at: DateTime.parse(r['created_at'] as String),
      );

  String get fdate => DateFormat('d MMM yyyy', 'es').format(at);
  String get initials {
    final p = userEmail.split('@')[0].split('.');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : userEmail[0].toUpperCase();
  }

  @override
  List<Object?> get props => [id, userId, productId];
}

// ── Repos ─────────────────────────────────────────────────────
class AuthRepo {
  final _sb = Supabase.instance.client;
  final _vault = const FlutterSecureStorage();
  final _g = GoogleSignIn();

  Future<void> signIn(String email, String pass) async {
    try {
      final r = await _sb.auth
          .signInWithPassword(email: email.trim(), password: pass);
      if (r.user == null) throw const AuthEx('Correo o contraseña incorrectos');
    } on AuthEx {
      rethrow;
    } catch (e) {
      throw AuthEx('Error: $e');
    }
  }

  Future<void> signUp(String email, String pass) async {
    try {
      final r = await _sb.auth.signUp(email: email.trim(), password: pass);
      if (r.user == null) throw const AuthEx('No se pudo crear la cuenta');
    } on AuthEx {
      rethrow;
    } catch (e) {
      throw AuthEx('Error: $e');
    }
  }

  Future<void> signInGoogle() async {
    try {
      final gu = await _g.signIn();
      if (gu == null) throw const AuthEx('Cancelado');
      final ga = await gu.authentication;
      if (ga.idToken == null) throw const AuthEx('Sin token');
      await _sb.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: ga.idToken!,
          accessToken: ga.accessToken);
    } on AuthEx {
      rethrow;
    } catch (e) {
      throw AuthEx('Error Google: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _g.signOut();
      await _sb.auth.signOut();
    } catch (_) {}
  }

  Future<void> saveCreds(String e, String p) async {
    await _vault.write(key: 'u', value: e);
    await _vault.write(key: 'p', value: p);
  }

  Future<Map<String, String>?> getCreds() async {
    final u = await _vault.read(key: 'u');
    final p = await _vault.read(key: 'p');
    if (u != null && p != null) return {'email': u, 'password': p};
    return null;
  }

  User? get me => _sb.auth.currentUser;
}

class ProductRepo {
  final _client = http.Client();
  final _cache = <int, Product>{};
  List<Product> _all = [];

  Future<List<Product>> fetchAll() async {
    if (_all.isNotEmpty) return _all;
    try {
      final r = await _client.get(Uri.parse('$_kBase/products'));
      if (r.statusCode != 200) throw NetEx('HTTP ${r.statusCode}');
      final data = json.decode(r.body) as List;
      _all =
          data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      for (final p in _all) {
        _cache[p.id] = p;
      }
      return _all;
    } on AppEx {
      rethrow;
    } catch (e) {
      throw NetEx('Error: $e');
    }
  }

  Future<Product> getById(int id) async {
    if (_cache.containsKey(id)) return _cache[id]!;
    await fetchAll();
    if (_cache.containsKey(id)) return _cache[id]!;
    throw NetEx('Producto $id no encontrado');
  }

  Future<List<String>> cats() async {
    try {
      final r = await _client.get(Uri.parse('$_kBase/products/categories'));
      if (r.statusCode != 200) return [];
      return (json.decode(r.body) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  List<Product> search(String q) {
    final t = q.toLowerCase();
    return _all
        .where((p) =>
            p.title.toLowerCase().contains(t) ||
            p.category.toLowerCase().contains(t))
        .toList();
  }

  List<Product> get deals => _all.where((p) => p.hasOffer).toList();
  List<Product> get top =>
      (List.of(_all)..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0)))
          .take(10)
          .toList();
}

// CartManager — estado local + sync Supabase
class CartManager extends ChangeNotifier {
  final _sb = Supabase.instance.client;
  final List<CartItem> _items = [];
  String? _uid;
  bool loading = false;

  List<CartItem> get items => List.unmodifiable(_items);
  double get total => _items.fold(0, (s, i) => s + i.sub);
  int get count => _items.fold(0, (s, i) => s + i.qty);
  bool get empty => _items.isEmpty;
  String get dtotal => '\$${total.toStringAsFixed(2)}';

  void init(String uid) {
    _uid = uid;
    _load();
  }

  Future<void> _load() async {
    if (_uid == null) return;
    loading = true;
    notifyListeners();
    try {
      final rows = await _sb.from('cart').select().eq('user_id', _uid!);
      _items.clear();
      for (final row in rows) {
        try {
          final res = await http
              .get(Uri.parse('$_kBase/products/${row['product_id']}'));
          if (res.statusCode == 200) {
            final p =
                Product.fromJson(json.decode(res.body) as Map<String, dynamic>);
            _items.add(CartItem(
                id: row['id'].toString(),
                product: p,
                qty: row['quantity'] as int));
          }
        } catch (_) {}
      }
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  Future<void> add(Product product, {int qty = 1}) async {
    final i = _items.indexWhere((x) => x.product.id == product.id);
    if (i >= 0) {
      _items[i] = _items[i].wq(_items[i].qty + qty);
      notifyListeners();
      if (_uid != null) {
        try {
          final rows = await _sb
              .from('cart')
              .select('id,quantity')
              .eq('user_id', _uid!)
              .eq('product_id', product.id);
          if (rows.isNotEmpty)
            await _sb
                .from('cart')
                .update({'quantity': _items[i].qty}).eq('id', rows[0]['id']);
        } catch (_) {}
      }
    } else {
      final tmp = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
      _items.add(CartItem(id: tmp, product: product, qty: qty));
      notifyListeners();
      if (_uid != null) {
        try {
          final res = await _sb.from('cart').insert({
            'user_id': _uid!,
            'product_id': product.id,
            'quantity': qty
          }).select();
          final idx = _items.indexWhere((x) => x.id == tmp);
          if (idx >= 0 && res.isNotEmpty) {
            _items[idx] = CartItem(
                id: res[0]['id'].toString(), product: product, qty: qty);
            notifyListeners();
          }
        } catch (_) {}
      }
    }
  }

  Future<void> setQty(CartItem item, int qty) async {
    if (qty <= 0) {
      await remove(item);
      return;
    }
    final i = _items.indexWhere((x) => x.id == item.id);
    if (i < 0) return;
    _items[i] = item.wq(qty);
    notifyListeners();
    if (_uid != null && !item.id.startsWith('tmp_')) {
      try {
        await _sb.from('cart').update({'quantity': qty}).eq('id', item.id);
      } catch (_) {}
    }
  }

  Future<void> remove(CartItem item) async {
    _items.removeWhere((x) => x.id == item.id);
    notifyListeners();
    if (_uid != null && !item.id.startsWith('tmp_')) {
      try {
        await _sb.from('cart').delete().eq('id', item.id);
      } catch (_) {}
    }
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    if (_uid != null) {
      try {
        await _sb.from('cart').delete().eq('user_id', _uid!);
      } catch (_) {}
    }
  }

  void reset() {
    _items.clear();
    _uid = null;
    notifyListeners();
  }
}

// OrderRepo
class OrderRepo {
  final _sb = Supabase.instance.client;

  Future<String> create(String uid, List<CartItem> items, double total,
      {String? address, String? cardLast4}) async {
    try {
      final res = await _sb.from('orders').insert({
        'user_id': uid,
        'total_amount': total,
        'status': 0,
        if (address != null) 'shipping_address': address,
        if (cardLast4 != null) 'card_last4': cardLast4,
      }).select();
      final oid = res[0]['id'].toString();
      for (final item in items) {
        await _sb.from('order_items').insert({
          'order_id': oid,
          'product_id': item.product.id,
          'quantity': item.qty,
          'price': item.product.price
        });
      }
      return oid;
    } catch (e) {
      throw OrderEx('No se pudo crear el pedido: $e');
    }
  }

  Future<List<Order>> getAll(String uid, ProductRepo pr) async {
    try {
      final rows = await _sb
          .from('orders')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      final out = <Order>[];
      for (final row in rows) {
        try {
          final irows =
              await _sb.from('order_items').select().eq('order_id', row['id']);
          final items = <OItem>[];
          for (final r in irows) {
            try {
              final p = await pr.getById(r['product_id'] as int);
              items.add(OItem(
                  product: p,
                  qty: r['quantity'] as int,
                  price: (r['price'] as num).toDouble()));
            } catch (_) {}
          }
          out.add(Order.fromRow(row, items));
        } catch (_) {}
      }
      return out;
    } catch (e) {
      throw OrderEx('Error al cargar pedidos: $e');
    }
  }
}

// ReviewRepo
class ReviewRepo {
  final _sb = Supabase.instance.client;
  Future<List<Review>> getFor(int pid) async {
    try {
      final rows = await _sb
          .from('reviews')
          .select()
          .eq('product_id', pid)
          .order('created_at', ascending: false);
      return rows.map((r) => Review.fromRow(r)).toList();
    } catch (e) {
      throw RevEx('Error: $e');
    }
  }

  Future<void> add(
      {required String uid,
      required String email,
      required int pid,
      required double rating,
      required String comment}) async {
    try {
      await _sb.from('reviews').insert({
        'user_id': uid,
        'user_email': email,
        'product_id': pid,
        'rating': rating,
        'comment': comment
      });
    } catch (e) {
      throw RevEx('Error: $e');
    }
  }

  Future<void> del(String id) async {
    try {
      await _sb.from('reviews').delete().eq('id', id);
    } catch (e) {
      throw RevEx('Error: $e');
    }
  }

  Future<bool> hasRev(String uid, int pid) async {
    try {
      final r = await _sb
          .from('reviews')
          .select('id')
          .eq('user_id', uid)
          .eq('product_id', pid)
          .maybeSingle();
      return r != null;
    } catch (_) {
      return false;
    }
  }
}

// ── Auth BLoC ──────────────────────────────────────────────────
abstract class AEv extends Equatable {
  const AEv();
  @override
  List<Object?> get props => [];
}

class CheckSess extends AEv {}

class DoLogin extends AEv {
  final String email, pass;
  final bool rem;
  const DoLogin({required this.email, required this.pass, this.rem = false});
  @override
  List<Object?> get props => [email, pass, rem];
}

class DoReg extends AEv {
  final String email, pass;
  const DoReg({required this.email, required this.pass});
  @override
  List<Object?> get props => [email, pass];
}

class DoGoogle extends AEv {}

class DoLogout extends AEv {}

abstract class ASt extends Equatable {
  const ASt();
  @override
  List<Object?> get props => [];
}

class AIdle extends ASt {}

class ABusy extends ASt {}

class AOk extends ASt {
  final String uid;
  final String? email;
  const AOk(this.uid, {this.email});
  @override
  List<Object?> get props => [uid];
}

class AOut extends ASt {}

class AFail extends ASt {
  final String msg;
  const AFail(this.msg);
  @override
  List<Object?> get props => [msg];
}

class ABloc extends Bloc<AEv, ASt> {
  final AuthRepo _r;
  ABloc(this._r) : super(AIdle()) {
    on<CheckSess>((e, emit) {
      final u = _r.me;
      emit(u != null ? AOk(u.id, email: u.email) : AOut());
    });
    on<DoLogin>((e, emit) async {
      emit(ABusy());
      try {
        await _r.signIn(e.email, e.pass);
        if (e.rem) await _r.saveCreds(e.email, e.pass);
        emit(AOk(_r.me!.id, email: _r.me!.email));
      } on AppEx catch (x) {
        emit(AFail(x.msg));
      } catch (x) {
        emit(AFail('Error: $x'));
      }
    });
    on<DoReg>((e, emit) async {
      emit(ABusy());
      try {
        await _r.signUp(e.email, e.pass);
        await _r.signIn(e.email, e.pass);
        emit(AOk(_r.me!.id, email: _r.me!.email));
      } on AppEx catch (x) {
        emit(AFail(x.msg));
      } catch (x) {
        emit(AFail('Error: $x'));
      }
    });
    on<DoGoogle>((e, emit) async {
      emit(ABusy());
      try {
        await _r.signInGoogle();
        emit(AOk(_r.me!.id, email: _r.me!.email));
      } on AppEx catch (x) {
        emit(AFail(x.msg));
      } catch (x) {
        emit(AFail('Error: $x'));
      }
    });
    on<DoLogout>((e, emit) async {
      await _r.signOut();
      emit(AOut());
    });
  }
}

// ── Product BLoC ───────────────────────────────────────────────
abstract class PEv extends Equatable {
  const PEv();
  @override
  List<Object?> get props => [];
}

class LoadP extends PEv {}

class FilterC extends PEv {
  final String? cat;
  const FilterC(this.cat);
  @override
  List<Object?> get props => [cat];
}

class SearchP extends PEv {
  final String q;
  const SearchP(this.q);
  @override
  List<Object?> get props => [q];
}

abstract class PSt extends Equatable {
  const PSt();
  @override
  List<Object?> get props => [];
}

class PIdle extends PSt {}

class PBusy extends PSt {}

class PReady extends PSt {
  final List<Product> all, shown, deals, top;
  final List<String> cats;
  final String? activeCat;
  const PReady(
      {required this.all,
      required this.shown,
      required this.deals,
      required this.top,
      required this.cats,
      this.activeCat});
  @override
  List<Object?> get props => [shown, activeCat];
}

class PFail extends PSt {
  final String msg;
  const PFail(this.msg);
  @override
  List<Object?> get props => [msg];
}

class PBloc extends Bloc<PEv, PSt> {
  final ProductRepo _r;
  PBloc(this._r) : super(PIdle()) {
    on<LoadP>((e, emit) async {
      emit(PBusy());
      try {
        final all = await _r.fetchAll();
        final cats = await _r.cats();
        emit(PReady(
            all: all, shown: all, deals: _r.deals, top: _r.top, cats: cats));
      } on AppEx catch (x) {
        emit(PFail(x.msg));
      }
    });
    on<FilterC>((e, emit) {
      final cur = state;
      if (cur is! PReady) return;
      final shown = e.cat == null
          ? cur.all
          : cur.all.where((p) => p.category == e.cat).toList();
      emit(PReady(
          all: cur.all,
          shown: shown,
          deals: cur.deals,
          top: cur.top,
          cats: cur.cats,
          activeCat: e.cat));
    });
    on<SearchP>((e, emit) {
      final cur = state;
      if (cur is! PReady) return;
      if (e.q.isEmpty) {
        emit(PReady(
            all: cur.all,
            shown: cur.all,
            deals: cur.deals,
            top: cur.top,
            cats: cur.cats));
        return;
      }
      emit(PReady(
          all: cur.all,
          shown: _r.search(e.q),
          deals: cur.deals,
          top: cur.top,
          cats: cur.cats,
          activeCat: null));
    });
  }
}

// ── Order BLoC ─────────────────────────────────────────────────
abstract class OEv extends Equatable {
  const OEv();
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OEv {}

class PlaceOrder extends OEv {
  final List<CartItem> items;
  final double total;
  final String? address;
  final String? cardLast4;
  const PlaceOrder(
      {required this.items, required this.total, this.address, this.cardLast4});
}

abstract class OSt extends Equatable {
  const OSt();
  @override
  List<Object?> get props => [];
}

class OIdle extends OSt {}

class OBusy extends OSt {}

class OReady extends OSt {
  final List<Order> orders;
  const OReady(this.orders);
  @override
  List<Object?> get props => [orders];
}

class ODone extends OSt {
  final String oid;
  const ODone(this.oid);
  @override
  List<Object?> get props => [oid];
}

class OFail extends OSt {
  final String msg;
  const OFail(this.msg);
  @override
  List<Object?> get props => [msg];
}

class OBloc extends Bloc<OEv, OSt> {
  final OrderRepo _repo;
  final ProductRepo _pr;
  final AuthRepo _auth;
  OBloc(this._repo, this._pr, this._auth) : super(OIdle()) {
    on<LoadOrders>((e, emit) async {
      final uid = _auth.me?.id;
      if (uid == null) return;
      emit(OBusy());
      try {
        await _pr.fetchAll();
        emit(OReady(await _repo.getAll(uid, _pr)));
      } on AppEx catch (x) {
        emit(OFail(x.msg));
      } catch (x) {
        emit(OFail('Error: $x'));
      }
    });
    on<PlaceOrder>((e, emit) async {
      final uid = _auth.me?.id;
      if (uid == null) return;
      emit(OBusy());
      try {
        final id = await _repo.create(uid, e.items, e.total,
            address: e.address, cardLast4: e.cardLast4);
        emit(ODone(id));
        add(LoadOrders());
      } on AppEx catch (x) {
        emit(OFail(x.msg));
      }
    });
  }
}

// ── Review BLoC ────────────────────────────────────────────────
abstract class REv extends Equatable {
  const REv();
  @override
  List<Object?> get props => [];
}

class LoadRevs extends REv {
  final int pid;
  const LoadRevs(this.pid);
  @override
  List<Object?> get props => [pid];
}

class PostRev extends REv {
  final int pid;
  final double rating;
  final String comment;
  const PostRev(
      {required this.pid, required this.rating, required this.comment});
}

class DelRev extends REv {
  final String id;
  final int pid;
  const DelRev(this.id, this.pid);
}

abstract class RSt extends Equatable {
  const RSt();
  @override
  List<Object?> get props => [];
}

class RIdle extends RSt {}

class RBusy extends RSt {}

class RReady extends RSt {
  final List<Review> reviews;
  final bool mine;
  const RReady(this.reviews, {this.mine = false});
  double get avg => reviews.isEmpty
      ? 0
      : reviews.fold(0.0, (s, r) => s + r.rating) / reviews.length;
  @override
  List<Object?> get props => [reviews, mine];
}

class RFail extends RSt {
  final String msg;
  const RFail(this.msg);
  @override
  List<Object?> get props => [msg];
}

class RBloc extends Bloc<REv, RSt> {
  final ReviewRepo _r;
  final AuthRepo _auth;
  RBloc(this._r, this._auth) : super(RIdle()) {
    on<LoadRevs>((e, emit) async {
      emit(RBusy());
      try {
        final revs = await _r.getFor(e.pid);
        final uid = _auth.me?.id;
        final mine = uid != null ? await _r.hasRev(uid, e.pid) : false;
        emit(RReady(revs, mine: mine));
      } on AppEx catch (x) {
        emit(RFail(x.msg));
      }
    });
    on<PostRev>((e, emit) async {
      final u = _auth.me;
      if (u == null) return;
      emit(RBusy());
      try {
        await _r.add(
            uid: u.id,
            email: u.email ?? 'Usuario',
            pid: e.pid,
            rating: e.rating,
            comment: e.comment);
        add(LoadRevs(e.pid));
      } on AppEx catch (x) {
        emit(RFail(x.msg));
      }
    });
    on<DelRev>((e, emit) async {
      try {
        await _r.del(e.id);
        add(LoadRevs(e.pid));
      } on AppEx catch (x) {
        emit(RFail(x.msg));
      }
    });
  }
}

// ── Animation helpers ─────────────────────────────────────────
class Slide extends StatefulWidget {
  final Widget child;
  final Duration delay, dur;
  final Offset begin;
  const Slide(
      {super.key,
      required this.child,
      this.delay = Duration.zero,
      this.dur = const Duration(milliseconds: 300),
      this.begin = const Offset(0, 0.06)});
  @override
  State<Slide> createState() => _SlideState();
}

class _SlideState extends State<Slide> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _op;
  late final Animation<Offset> _sl;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.dur);
    _op = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _sl = Tween<Offset>(begin: widget.begin, end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => FadeTransition(
      opacity: _op, child: SlideTransition(position: _sl, child: widget.child));
}

class Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Press({super.key, required this.child, this.onTap});
  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _a = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) {
          _c.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
            animation: _a,
            builder: (_, child) =>
                Transform.scale(scale: _a.value, child: child),
            child: widget.child),
      );
}

// ── Shared UI ─────────────────────────────────────────────────
class AB extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Color? bg, fg;
  final IconData? icon;
  final double? width;
  const AB(
      {super.key,
      required this.label,
      this.onTap,
      this.loading = false,
      this.bg,
      this.fg,
      this.icon,
      this.width});
  @override
  Widget build(BuildContext ctx) => SizedBox(
        width: width ?? double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: bg, foregroundColor: fg),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : icon != null
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 16),
                      const SizedBox(width: 6),
                      Text(label)
                    ])
                  : Text(label),
        ),
      );
}

class AF extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool secret;
  final TextInputType type;
  final String? Function(String?)? validate;
  final Widget? lead, trail;
  final int? maxLen;
  const AF(
      {super.key,
      required this.ctrl,
      required this.hint,
      this.secret = false,
      this.type = TextInputType.text,
      this.validate,
      this.lead,
      this.trail,
      this.maxLen});
  @override
  Widget build(BuildContext ctx) => TextFormField(
        controller: ctrl,
        obscureText: secret,
        keyboardType: type,
        validator: validate,
        maxLength: maxLen,
        decoration: InputDecoration(
            labelText: hint,
            prefixIcon: lead,
            suffixIcon: trail,
            counterText: maxLen != null ? null : ''),
      );
}

class PImg extends StatelessWidget {
  final String url, tag;
  final double? height;
  final BoxFit fit;
  const PImg(
      {super.key,
      required this.url,
      required this.tag,
      this.height,
      this.fit = BoxFit.contain});
  @override
  Widget build(BuildContext ctx) => Hero(
        tag: 'p-$tag',
        child: CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          height: height,
          placeholder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[50]!,
              child: Container(color: Colors.white)),
          errorWidget: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.grey, size: 24)),
        ),
      );
}

class Stars extends StatelessWidget {
  final double? val;
  final int? count;
  final double size;
  const Stars({super.key, this.val, this.count, this.size = 13});
  @override
  Widget build(BuildContext ctx) {
    if (val == null) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(
          5,
          (i) => Icon(
              i < val!.round()
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: const Color(0xFFFF8F00))),
      if (count != null) ...[
        const SizedBox(width: 4),
        Text('$count', style: TextStyle(fontSize: size - 1, color: C.blue))
      ],
    ]);
  }
}

class CartDot extends StatelessWidget {
  final Widget child;
  const CartDot({super.key, required this.child});
  @override
  Widget build(BuildContext ctx) {
    final n = ctx.watch<CartManager>().count;
    return Stack(clipBehavior: Clip.none, children: [
      child,
      if (n > 0)
        Positioned(
            right: -2,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration:
                  const BoxDecoration(color: C.orange, shape: BoxShape.circle),
              child: Text(n > 99 ? '99+' : '$n',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            )),
    ]);
  }
}

class Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  final String? btnLabel;
  final VoidCallback? onBtn;
  const Empty(
      {super.key,
      required this.icon,
      required this.title,
      this.sub,
      this.btnLabel,
      this.onBtn});
  @override
  Widget build(BuildContext ctx) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Slide(
                child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: C.blue.withOpacity(0.07),
                        shape: BoxShape.circle),
                    child:
                        Icon(icon, size: 52, color: C.blue.withOpacity(0.35)))),
            const SizedBox(height: 16),
            Slide(
                delay: const Duration(milliseconds: 60),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: C.ink),
                    textAlign: TextAlign.center)),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Slide(
                  delay: const Duration(milliseconds: 100),
                  child: Text(sub!,
                      style: const TextStyle(color: C.muted),
                      textAlign: TextAlign.center))
            ],
            if (btnLabel != null && onBtn != null) ...[
              const SizedBox(height: 18),
              Slide(
                  delay: const Duration(milliseconds: 140),
                  child: AB(label: btnLabel!, onTap: onBtn, width: 160))
            ],
          ])));
}

class ErrBox extends StatelessWidget {
  final String msg;
  final VoidCallback retry;
  const ErrBox({super.key, required this.msg, required this.retry});
  @override
  Widget build(BuildContext ctx) => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: C.danger),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.muted)),
            const SizedBox(height: 18),
            AB(
                label: 'Reintentar',
                onTap: retry,
                icon: Icons.refresh_rounded,
                width: 140),
          ])));
}

// ── Root & Shell ───────────────────────────────────────────────
class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  void initState() {
    super.initState();
    context.read<ABloc>().add(CheckSess());
  }

  @override
  Widget build(BuildContext ctx) => BlocConsumer<ABloc, ASt>(
        listener: (ctx, st) {
          if (st is AOk) {
            ctx.read<CartManager>().init(st.uid);
            ctx.read<OBloc>().add(LoadOrders());
            ctx.read<PBloc>().add(LoadP());
          }
          if (st is AOut) ctx.read<CartManager>().reset();
        },
        builder: (_, st) {
          if (st is AIdle || st is ABusy)
            return const Scaffold(
                backgroundColor: C.navy,
                body:
                    Center(child: CircularProgressIndicator(color: C.orange)));
          if (st is AOk) return const Shell();
          return const LoginScreen();
        },
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  static const _screens = [
    HomeScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen()
  ];
  @override
  Widget build(BuildContext ctx) => Scaffold(
        body: IndexedStack(index: _tab, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2))
          ]),
          child: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) {
              HapticFeedback.selectionClick();
              setState(() => _tab = i);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: C.orange,
            unselectedItemColor: C.muted,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Inicio'),
              BottomNavigationBarItem(
                  icon:
                      CartDot(child: const Icon(Icons.shopping_cart_outlined)),
                  activeIcon: CartDot(child: const Icon(Icons.shopping_cart)),
                  label: 'Carrito'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Pedidos'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Perfil'),
            ],
          ),
        ),
      );
}

// ── Login & Register ───────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _rem = false, _hide = true;
  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _go() {
    if (!_form.currentState!.validate()) return;
    context
        .read<ABloc>()
        .add(DoLogin(email: _email.text.trim(), pass: _pass.text, rem: _rem));
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.navy,
        body: BlocListener<ABloc, ASt>(
          listener: (ctx, st) {
            if (st is AFail)
              ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(st.msg), backgroundColor: C.danger));
          },
          child: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Slide(
                  child: const Text('amazon',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic))),
              const SizedBox(height: 22),
              Slide(
                  delay: const Duration(milliseconds: 60),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(r8),
                        border: Border.all(color: C.line)),
                    child: Form(
                        key: _form,
                        child: Column(children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Iniciar sesión',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500))),
                          const SizedBox(height: 16),
                          AF(
                              ctrl: _email,
                              hint: 'Correo electrónico',
                              type: TextInputType.emailAddress,
                              validate: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Requerido';
                                if (!v.contains('@')) return 'Inválido';
                                return null;
                              }),
                          const SizedBox(height: 12),
                          AF(
                              ctrl: _pass,
                              hint: 'Contraseña',
                              secret: _hide,
                              trail: IconButton(
                                  icon: Icon(
                                      _hide
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18),
                                  onPressed: () =>
                                      setState(() => _hide = !_hide)),
                              validate: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (v.length < 6) return 'Mín. 6';
                                return null;
                              }),
                          const SizedBox(height: 6),
                          Row(children: [
                            Checkbox(
                                value: _rem,
                                onChanged: (v) =>
                                    setState(() => _rem = v ?? false),
                                activeColor: C.orange,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            const Text('Recordar mis datos',
                                style: TextStyle(fontSize: 13))
                          ]),
                          const SizedBox(height: 12),
                          BlocBuilder<ABloc, ASt>(
                              builder: (_, st) => AB(
                                  label: 'Continuar',
                                  onTap: _go,
                                  loading: st is ABusy)),
                          const SizedBox(height: 14),
                          const Row(children: [
                            Expanded(child: Divider()),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('o',
                                    style: TextStyle(color: C.muted))),
                            Expanded(child: Divider())
                          ]),
                          const SizedBox(height: 14),
                          OutlinedButton(
                              onPressed: () =>
                                  ctx.read<ABloc>().add(DoGoogle()),
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 44),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(r4)),
                                  side: const BorderSide(color: C.line)),
                              child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.g_mobiledata,
                                        size: 22, color: C.ink),
                                    SizedBox(width: 8),
                                    Text('Continuar con Google',
                                        style: TextStyle(
                                            color: C.ink,
                                            fontWeight: FontWeight.w500))
                                  ])),
                        ])),
                  )),
              const SizedBox(height: 14),
              Slide(
                  delay: const Duration(milliseconds: 110),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(r8),
                        border: Border.all(color: C.line)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿Nuevo en Amazon?',
                              style: TextStyle(fontSize: 13)),
                          TextButton(
                              onPressed: () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                      builder: (_) => const RegScreen())),
                              child: const Text('Crear cuenta')),
                        ]),
                  )),
            ]),
          ))),
        ),
      );
}

class RegScreen extends StatefulWidget {
  const RegScreen({super.key});
  @override
  State<RegScreen> createState() => _RegState();
}

class _RegState extends State<RegScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _conf = TextEditingController();
  bool _hp = true, _hc = true;
  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _conf.dispose();
    super.dispose();
  }

  void _go() {
    if (!_form.currentState!.validate()) return;
    context
        .read<ABloc>()
        .add(DoReg(email: _email.text.trim(), pass: _pass.text));
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.navy,
        appBar: AppBar(title: const Text('Crear cuenta')),
        body: BlocListener<ABloc, ASt>(
          listener: (ctx, st) {
            if (st is AFail)
              ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(st.msg), backgroundColor: C.danger));
          },
          child: SafeArea(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(r8),
                        border: Border.all(color: C.line)),
                    child: Form(
                        key: _form,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Crea tu cuenta',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 16),
                              AF(
                                  ctrl: _email,
                                  hint: 'Correo electrónico',
                                  type: TextInputType.emailAddress,
                                  validate: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Requerido';
                                    if (!v.contains('@')) return 'Inválido';
                                    return null;
                                  }),
                              const SizedBox(height: 12),
                              AF(
                                  ctrl: _pass,
                                  hint: 'Contraseña',
                                  secret: _hp,
                                  trail: IconButton(
                                      icon: Icon(
                                          _hp
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 18),
                                      onPressed: () =>
                                          setState(() => _hp = !_hp)),
                                  validate: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Requerido';
                                    if (v.length < 6) return 'Mín. 6';
                                    return null;
                                  }),
                              const SizedBox(height: 12),
                              AF(
                                  ctrl: _conf,
                                  hint: 'Confirmar contraseña',
                                  secret: _hc,
                                  trail: IconButton(
                                      icon: Icon(
                                          _hc
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 18),
                                      onPressed: () =>
                                          setState(() => _hc = !_hc)),
                                  validate: (v) =>
                                      v != _pass.text ? 'No coinciden' : null),
                              const SizedBox(height: 20),
                              BlocBuilder<ABloc, ASt>(
                                  builder: (_, st) => AB(
                                      label: 'Crear cuenta',
                                      onTap: _go,
                                      loading: st is ABusy)),
                            ])),
                  ))),
        ),
      );
}

// ── Home Screen ────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  final _sc = TextEditingController();
  Timer? _t;
  bool _searching = false;

  void _type(String v) {
    _t?.cancel();
    setState(() => _searching = v.isNotEmpty);
    _t = Timer(const Duration(milliseconds: _kMs),
        () => context.read<PBloc>().add(SearchP(v)));
  }

  @override
  void dispose() {
    _t?.cancel();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.bg,
        body: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: C.navy,
              toolbarHeight: 56,
              title: Container(
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.all(r4)),
                child: TextField(
                  controller: _sc,
                  onChanged: _type,
                  decoration: InputDecoration(
                    hintText: 'Buscar en Amazon 2026',
                    hintStyle: const TextStyle(fontSize: 14, color: C.muted),
                    prefixIcon:
                        const Icon(Icons.search, color: C.muted, size: 20),
                    suffixIcon: _searching
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _sc.clear();
                              _type('');
                            })
                        : const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.mic_outlined,
                                color: C.muted, size: 18)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              actions: [
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CartDot(
                        child: IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined,
                                color: Colors.white),
                            onPressed: () {})))
              ],
            ),
          ],
          body: BlocBuilder<PBloc, PSt>(
            builder: (ctx, st) {
              if (st is PIdle || st is PBusy)
                return const Center(
                    child: CircularProgressIndicator(color: C.orange));
              if (st is PFail)
                return ErrBox(
                    msg: st.msg, retry: () => ctx.read<PBloc>().add(LoadP()));
              if (st is PReady) {
                if (_searching) return _SResults(items: st.shown);
                return _Feed(st: st);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
}

class _Feed extends StatelessWidget {
  final PReady st;
  const _Feed({required this.st});

  @override
  Widget build(BuildContext ctx) => RefreshIndicator(
        color: C.orange,
        onRefresh: () async {
          ctx.read<PBloc>().add(LoadP());
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(children: [
          _Banner(),
          const SizedBox(height: 8),
          _Cats(st: st),
          const SizedBox(height: 8),
          if (st.deals.isNotEmpty) ...[
            _Sec(
                title: '🔥 Ofertas del día',
                color: C.deal,
                child: SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: st.deals.length,
                      itemBuilder: (ctx, i) => Slide(
                          delay: Duration(milliseconds: i * 40),
                          child: _DCard(p: st.deals[i])),
                    ))),
            const SizedBox(height: 8),
          ],
          _Sec(
              title: '⭐ Más valorados',
              child: SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: st.top.length,
                    itemBuilder: (ctx, i) => Slide(
                        delay: Duration(milliseconds: i * 35),
                        child: _SCard(p: st.top[i])),
                  ))),
          const SizedBox(height: 8),
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                st.activeCat != null
                    ? _catL(st.activeCat!).toUpperCase()
                    : 'Todos los productos',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: C.ink),
              )),
          // Grid responsivo — tarjetas más compactas
          LayoutBuilder(builder: (ctx, box) {
            final cols = box.maxWidth > 600 ? 3 : 2;
            final ratio = box.maxWidth > 600 ? 0.68 : 0.70;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: ratio),
              itemCount: st.shown.length,
              itemBuilder: (ctx, i) => Slide(
                  delay: Duration(milliseconds: (i % 4) * 40),
                  child: _GCard(p: st.shown[i])),
            );
          }),
          const SizedBox(height: 24),
        ]),
      );

  String _catL(String c) =>
      {
        'men\'s clothing': 'Hombre',
        'women\'s clothing': 'Mujer',
        'jewelery': 'Joyería',
        'electronics': 'Electrónica'
      }[c] ??
      c;
}

class _Banner extends StatefulWidget {
  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  final _pc = PageController();
  int _p = 0;
  Timer? _t;
  static const _items = [
    {
      'bg': Color(0xFF131921),
      'txt': 'Envío GRATIS en tu primer pedido',
      'sub': 'Millones de productos disponibles',
      'ic': Icons.local_shipping_outlined
    },
    {
      'bg': Color(0xFF0071A2),
      'txt': 'Ofertas exclusivas hoy',
      'sub': 'Descuentos de hasta el 40%',
      'ic': Icons.local_offer_outlined
    },
    {
      'bg': Color(0xFFC7511F),
      'txt': 'Amazon Prime',
      'sub': 'Entrega rápida y streaming ilimitado',
      'ic': Icons.star_outline_rounded
    },
  ];
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _p = (_p + 1) % _items.length;
      _pc.animateToPage(_p,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Column(children: [
        SizedBox(
            height: 130,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() => _p = i),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final b = _items[i];
                return Container(
                  color: b['bg'] as Color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text(b['txt'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3)),
                          const SizedBox(height: 5),
                          Text(b['sub'] as String,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12)),
                        ])),
                    Icon(b['ic'] as IconData,
                        color: Colors.white.withOpacity(0.2), size: 52),
                  ]),
                );
              },
            )),
        Container(
          color: (_items[_p]['bg'] as Color).withOpacity(0.9),
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  _items.length,
                  (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _p == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: _p == i
                                ? C.orange
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.all(r99)),
                      ))),
        ),
      ]);
}

class _Cats extends StatelessWidget {
  final PReady st;
  const _Cats({required this.st});
  static const _lbl = {
    'men\'s clothing': 'Hombre',
    'women\'s clothing': 'Mujer',
    'jewelery': 'Joyería',
    'electronics': 'Electrónica'
  };
  @override
  Widget build(BuildContext ctx) => SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _Chip(
              label: 'Todo',
              active: st.activeCat == null,
              onTap: () => ctx.read<PBloc>().add(FilterC(null))),
          ...st.cats.map((c) => _Chip(
              label: _lbl[c] ?? c,
              active: st.activeCat == c,
              onTap: () => ctx.read<PBloc>().add(FilterC(c)))),
        ],
      ));
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
              color: active ? C.navy : Colors.white,
              borderRadius: BorderRadius.all(r99),
              border: Border.all(color: active ? C.navy : C.line)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : C.ink)),
        ),
      );
}

class _Sec extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? color;
  const _Sec({required this.title, required this.child, this.color});
  @override
  Widget build(BuildContext ctx) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color ?? C.ink))),
        child,
      ]);
}

// Deal card — horizontal list, bigger image ratio
class _DCard extends StatelessWidget {
  final Product p;
  const _DCard({required this.p});
  @override
  Widget build(BuildContext ctx) => Press(
        onTap: () => _open(ctx),
        child: Container(
          width: 140,
          decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.all(r8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: r8),
                  child: Container(
                      height: 100,
                      color: Colors.grey[50],
                      padding: const EdgeInsets.all(8),
                      child: PImg(url: p.image, tag: 'd-${p.id}', height: 84))),
              if (p.discount != null)
                Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: const BoxDecoration(
                            color: C.deal, borderRadius: BorderRadius.all(r4)),
                        child: Text('-${p.discount}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)))),
            ]),
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: C.ink, height: 1.3)),
                      const SizedBox(height: 4),
                      Text(p.dp,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: C.ink)),
                      if (p.origPrice != null)
                        Text(p.op,
                            style: const TextStyle(
                                fontSize: 10,
                                color: C.muted,
                                decoration: TextDecoration.lineThrough)),
                    ])),
          ]),
        ),
      );
  void _open(BuildContext ctx) => Navigator.push(
      ctx,
      PageRouteBuilder(
          pageBuilder: (_, __, ___) => DetailScreen(product: p),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 240)));
}

// Small top-rated card
class _SCard extends StatelessWidget {
  final Product p;
  const _SCard({required this.p});
  @override
  Widget build(BuildContext ctx) => Press(
        onTap: () => Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => DetailScreen(product: p))),
        child: Container(
          width: 130,
          decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.all(r8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
                borderRadius: const BorderRadius.vertical(top: r8),
                child: Container(
                    height: 110,
                    color: Colors.grey[50],
                    padding: const EdgeInsets.all(8),
                    child: PImg(url: p.image, tag: 't-${p.id}'))),
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: C.ink, height: 1.3)),
                      const SizedBox(height: 3),
                      Stars(val: p.rating, size: 11),
                      const SizedBox(height: 3),
                      Text(p.dp,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: C.ink)),
                    ])),
          ]),
        ),
      );
}

// Grid card — compact, Amazon-style
class _GCard extends StatelessWidget {
  final Product p;
  const _GCard({required this.p});
  @override
  Widget build(BuildContext ctx) => Press(
        onTap: () => Navigator.push(
            ctx,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => DetailScreen(product: p),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
                transitionDuration: const Duration(milliseconds: 230))),
        child: Container(
          decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.all(r8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Image — fixed height, not using Expanded so it doesn't grow
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: r8),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  color: Colors.grey[50],
                  padding: const EdgeInsets.all(10),
                  child: PImg(url: p.image, tag: '${p.id}'),
                ),
              ),
              if (p.hasOffer)
                Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                          color: C.deal, borderRadius: BorderRadius.all(r4)),
                      child: Text('-${p.discount}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    )),
            ]),
            // Info area
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: C.ink, height: 1.3)),
                          const SizedBox(height: 3),
                          Stars(val: p.rating, count: p.ratingCount, size: 11),
                          const Spacer(),
                          Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(p.dp,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: C.ink)),
                                  if (p.origPrice != null)
                                    Text(p.op,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: C.muted,
                                            decoration:
                                                TextDecoration.lineThrough)),
                                ])),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ctx.read<CartManager>().add(p);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text('Agregado al carrito'),
                                        duration: Duration(seconds: 1),
                                        backgroundColor: C.green));
                              },
                              child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                      color: C.yellow, shape: BoxShape.circle),
                                  child: const Icon(Icons.add_shopping_cart,
                                      size: 14, color: C.ink)),
                            ),
                          ]),
                        ]))),
          ]),
        ),
      );
}

class _SResults extends StatelessWidget {
  final List<Product> items;
  const _SResults({required this.items});
  @override
  Widget build(BuildContext ctx) {
    if (items.isEmpty)
      return const Empty(
          icon: Icons.search_off,
          title: 'Sin resultados',
          sub: 'Prueba con otro término');
    return ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: items.length,
        itemBuilder: (ctx, i) => Slide(
            delay: Duration(milliseconds: i * 30), child: _SRow(p: items[i])));
  }
}

class _SRow extends StatelessWidget {
  final Product p;
  const _SRow({required this.p});
  @override
  Widget build(BuildContext ctx) => Press(
        onTap: () => Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => DetailScreen(product: p))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.all(r8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)
              ]),
          child: Row(children: [
            Container(
                width: 65,
                height: 65,
                color: Colors.grey[50],
                padding: const EdgeInsets.all(6),
                child: PImg(url: p.image, tag: 's-${p.id}')),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: C.ink)),
                  const SizedBox(height: 3),
                  Stars(val: p.rating, count: p.ratingCount, size: 12),
                  const SizedBox(height: 3),
                  Text(p.dp,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: C.ink)),
                ])),
            IconButton(
              icon:
                  const Icon(Icons.add_shopping_cart_outlined, color: C.orange),
              onPressed: () {
                ctx.read<CartManager>().add(p);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Agregado'), duration: Duration(seconds: 1)));
              },
            ),
          ]),
        ),
      );
}

// ── Detail Screen ──────────────────────────────────────────────
class DetailScreen extends StatefulWidget {
  final Product product;
  const DetailScreen({super.key, required this.product});
  @override
  State<DetailScreen> createState() => _DState();
}

class _DState extends State<DetailScreen> {
  int _qty = 1;
  @override
  void initState() {
    super.initState();
    context.read<RBloc>().add(LoadRevs(widget.product.id));
  }

  @override
  Widget build(BuildContext ctx) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Detalle'), actions: [
        Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CartDot(
                child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white),
                    onPressed: () {})))
      ]),
      body: ListView(children: [
        Container(
            color: C.card,
            padding: const EdgeInsets.all(20),
            child: PImg(url: p.image, tag: '${p.id}', height: 240)),
        Container(
            color: C.card,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              Slide(
                  child: Text(p.title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: C.ink,
                          height: 1.3))),
              const SizedBox(height: 8),
              Slide(
                  delay: const Duration(milliseconds: 50),
                  child: Row(children: [
                    Stars(val: p.rating, count: p.ratingCount, size: 14),
                    const SizedBox(width: 8),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: C.green.withOpacity(0.1),
                            borderRadius: BorderRadius.all(r4)),
                        child: const Text('En stock',
                            style: TextStyle(
                                color: C.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                  ])),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              Slide(
                  delay: const Duration(milliseconds: 80),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p.dp,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: C.ink)),
                        if (p.origPrice != null) ...[
                          const SizedBox(width: 8),
                          Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.op,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: C.muted,
                                            decoration:
                                                TextDecoration.lineThrough)),
                                    if (p.discount != null)
                                      Text('-${p.discount}%',
                                          style: const TextStyle(
                                              color: C.deal,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                  ]))
                        ],
                      ])),
              const SizedBox(height: 4),
              const Text('+ Envío GRATIS',
                  style: TextStyle(color: C.blue, fontSize: 12)),
            ])),
        const SizedBox(height: 8),
        Container(
            color: C.card,
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                const Text('Cantidad:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: C.line),
                        borderRadius: BorderRadius.all(r4)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      InkWell(
                          onTap: _qty > 1 ? () => setState(() => _qty--) : null,
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.remove,
                                  size: 16,
                                  color: _qty > 1 ? C.ink : Colors.grey[300]))),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_qty',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15))),
                      InkWell(
                          onTap: () => setState(() => _qty++),
                          child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.add, size: 16, color: C.ink))),
                    ])),
              ]),
              const SizedBox(height: 14),
              AB(
                  label: 'Agregar al carrito',
                  icon: Icons.add_shopping_cart,
                  bg: C.yellow,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ctx.read<CartManager>().add(p, qty: _qty);
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: const Text('Agregado al carrito'),
                        backgroundColor: C.green,
                        action: SnackBarAction(
                            label: 'Ver carrito',
                            textColor: Colors.white,
                            onPressed: () => Navigator.pop(ctx))));
                  }),
              const SizedBox(height: 8),
              AB(
                  label: 'Comprar ahora',
                  icon: Icons.bolt,
                  bg: C.orange,
                  fg: Colors.white,
                  onTap: () {
                    ctx.read<CartManager>().add(p, qty: _qty);
                    Navigator.pop(ctx);
                  }),
            ])),
        const SizedBox(height: 8),
        Container(
            color: C.card,
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Descripción',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: C.ink)),
              const SizedBox(height: 8),
              Text(p.description,
                  style: const TextStyle(
                      color: C.muted, height: 1.6, fontSize: 13.5)),
            ])),
        const SizedBox(height: 8),
        _RevBlock(p: p),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _RevBlock extends StatelessWidget {
  final Product p;
  const _RevBlock({required this.p});
  @override
  Widget build(BuildContext ctx) => BlocBuilder<RBloc, RSt>(
      builder: (ctx, st) => Container(
            color: C.card,
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Opiniones de clientes',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: C.ink)),
                const Spacer(),
                if (st is RReady && !st.mine)
                  TextButton.icon(
                      onPressed: () => _sheet(ctx),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Escribir',
                          style: TextStyle(fontSize: 13))),
              ]),
              const SizedBox(height: 12),
              if (st is RBusy)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator())),
              if (st is RFail)
                Text(st.msg,
                    style: const TextStyle(color: C.danger, fontSize: 13)),
              if (st is RReady) ...[
                if (st.reviews.isNotEmpty) ...[
                  _RevSum(st: st),
                  const SizedBox(height: 12),
                  ...st.reviews.asMap().entries.map((e) => Slide(
                      delay: Duration(milliseconds: e.key * 50),
                      child: _RevItem(r: e.value, pid: p.id)))
                ] else
                  Column(children: [
                    const SizedBox(height: 8),
                    Icon(Icons.rate_review_outlined,
                        size: 36, color: Colors.grey[300]),
                    const SizedBox(height: 6),
                    const Text('Sin opiniones todavía',
                        style: TextStyle(color: C.muted, fontSize: 13)),
                    const SizedBox(height: 10),
                    if (!st.mine)
                      AB(
                          label: 'Sé el primero',
                          onTap: () => _sheet(ctx),
                          width: 150)
                  ]),
              ],
            ]),
          ));
  void _sheet(BuildContext ctx) => showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
          value: ctx.read<RBloc>(), child: _RevSheet(pid: p.id)));
}

class _RevSum extends StatelessWidget {
  final RReady st;
  const _RevSum({required this.st});
  @override
  Widget build(BuildContext ctx) {
    final avg = st.avg;
    return Row(children: [
      Column(children: [
        Text(avg.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 38, fontWeight: FontWeight.bold, color: C.ink)),
        Stars(val: avg, size: 15),
        const SizedBox(height: 2),
        Text(
            '${st.reviews.length} opinión${st.reviews.length != 1 ? 'es' : ''}',
            style: const TextStyle(fontSize: 11, color: C.muted)),
      ]),
      const SizedBox(width: 18),
      Expanded(
          child: Column(
              children: List.generate(5, (i) {
        final s = 5 - i;
        final c = st.reviews.where((r) => r.rating.round() == s).length;
        final pct = st.reviews.isEmpty ? 0.0 : c / st.reviews.length;
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Text('$s', style: const TextStyle(fontSize: 11, color: C.blue)),
              const SizedBox(width: 4),
              Expanded(
                  child: ClipRRect(
                      borderRadius: BorderRadius.all(r99),
                      child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 7,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFFF8F00))))),
              const SizedBox(width: 4),
              Text('$c', style: const TextStyle(fontSize: 10, color: C.muted)),
            ]));
      }))),
    ]);
  }
}

class _RevItem extends StatelessWidget {
  final Review r;
  final int pid;
  const _RevItem({required this.r, required this.pid});
  @override
  Widget build(BuildContext ctx) {
    final me = ctx.read<ABloc>().state;
    final mine = me is AOk && me.uid == r.userId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.all(r8),
          border: Border.all(color: C.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              radius: 16,
              backgroundColor: C.navy,
              child: Text(r.initials,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(r.userEmail.split('@')[0],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(r.fdate,
                    style: const TextStyle(fontSize: 11, color: C.muted))
              ])),
          Stars(val: r.rating, size: 13),
          if (mine)
            GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ctx.read<RBloc>().add(DelRev(r.id, pid));
                },
                child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child:
                        Icon(Icons.delete_outline, size: 16, color: C.muted))),
        ]),
        const SizedBox(height: 8),
        Text(r.comment,
            style: const TextStyle(fontSize: 13, color: C.ink, height: 1.5)),
      ]),
    );
  }
}

class _RevSheet extends StatefulWidget {
  final int pid;
  const _RevSheet({required this.pid});
  @override
  State<_RevSheet> createState() => _RevSheetState();
}

class _RevSheetState extends State<_RevSheet> {
  final _ctrl = TextEditingController();
  double _r = 0;
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _lbl(double r) => r <= 1
      ? 'Muy malo'
      : r <= 2
          ? 'Malo'
          : r <= 3
              ? 'Regular'
              : r <= 4
                  ? 'Bueno'
                  : '¡Excelente!';
  void _send() {
    if (_r == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elige una calificación')));
      return;
    }
    if (_ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Escribe algo')));
      return;
    }
    context
        .read<RBloc>()
        .add(PostRev(pid: widget.pid, rating: _r, comment: _ctrl.text.trim()));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Opinión publicada ✓'), backgroundColor: C.green));
  }

  @override
  Widget build(BuildContext ctx) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.all(r99)))),
              const SizedBox(height: 16),
              const Text('Escribe tu opinión',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Center(
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                          5,
                          (i) => GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _r = i + 1.0);
                                },
                                child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 160),
                                    child: Icon(
                                        i < _r
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        key: ValueKey('$i-${i < _r}'),
                                        size: 40,
                                        color: const Color(0xFFFF8F00))),
                              )))),
              const SizedBox(height: 6),
              Center(
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Text(_r == 0 ? 'Toca para calificar' : _lbl(_r),
                          key: ValueKey(_r),
                          style: TextStyle(
                              color:
                                  _r == 0 ? C.muted : const Color(0xFFFF8F00),
                              fontWeight:
                                  _r == 0 ? FontWeight.normal : FontWeight.w600,
                              fontSize: 13)))),
              const SizedBox(height: 16),
              TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: const InputDecoration(
                      hintText: 'Cuéntanos tu experiencia...',
                      alignLabelWithHint: true)),
              const SizedBox(height: 14),
              AB(
                  label: 'Publicar opinión',
                  onTap: _send,
                  icon: Icons.send_rounded),
            ]),
      );
}

// ── Cart Screen ────────────────────────────────────────────────
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(title: const Text('Carrito de compras'), actions: [
          Consumer<CartManager>(builder: (ctx, cart, _) {
            if (cart.empty) return const SizedBox.shrink();
            return TextButton(
                onPressed: () => _confirmClear(ctx, cart),
                child: const Text('Vaciar',
                    style: TextStyle(color: Colors.white70, fontSize: 13)));
          }),
        ]),
        body: Consumer<CartManager>(builder: (ctx, cart, _) {
          if (cart.loading)
            return const Center(
                child: CircularProgressIndicator(color: C.orange));
          if (cart.empty)
            return const Empty(
                icon: Icons.shopping_cart_outlined,
                title: 'Tu carrito está vacío',
                sub: 'Explora y agrega productos');
          return Column(children: [
            Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) => Slide(
                        delay: Duration(milliseconds: i * 40),
                        child: _CRow(item: cart.items[i])))),
            _CFooter(cart: cart),
          ]);
        }),
      );

  void _confirmClear(BuildContext ctx, CartManager cart) => showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
                title: const Text('¿Vaciar carrito?'),
                content: const Text('Se eliminan todos los productos.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Vaciar',
                          style: TextStyle(color: C.danger)))
                ],
              )).then((ok) {
        if (ok == true) cart.clear();
      });
}

class _CRow extends StatelessWidget {
  final CartItem item;
  const _CRow({required this.item});
  @override
  Widget build(BuildContext ctx) {
    final cart = ctx.read<CartManager>();
    return Dismissible(
      key: Key('c-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        cart.remove(item);
      },
      background: Container(
          alignment: Alignment.centerRight,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
              color: C.danger, borderRadius: BorderRadius.all(r8)),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(height: 2),
            Text('Quitar', style: TextStyle(color: Colors.white, fontSize: 10))
          ])),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.all(r8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)
            ]),
        child: Row(children: [
          Container(
              width: 78,
              height: 78,
              color: Colors.grey[50],
              padding: const EdgeInsets.all(6),
              child: PImg(url: item.product.image, tag: 'c-${item.id}')),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: C.ink)),
                const SizedBox(height: 3),
                const Text('Envío GRATIS',
                    style: TextStyle(color: C.blue, fontSize: 11)),
                const SizedBox(height: 8),
                Row(children: [
                  _QCtrl(item: item),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(item.dsub,
                            key: ValueKey(item.qty),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: C.ink))),
                    Text('${item.product.dp} c/u',
                        style: const TextStyle(fontSize: 11, color: C.muted)),
                  ]),
                ]),
              ])),
        ]),
      ),
    );
  }
}

class _QCtrl extends StatelessWidget {
  final CartItem item;
  const _QCtrl({required this.item});
  @override
  Widget build(BuildContext ctx) {
    final cart = ctx.read<CartManager>();
    return Container(
        decoration: BoxDecoration(
            border: Border.all(color: C.line),
            borderRadius: BorderRadius.all(r4)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          InkWell(
              onTap: item.qty > 1
                  ? () {
                      HapticFeedback.lightImpact();
                      cart.setQty(item, item.qty - 1);
                    }
                  : null,
              borderRadius: BorderRadius.all(r4),
              child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.remove,
                      size: 14,
                      color: item.qty > 1 ? C.ink : Colors.grey[300]))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text('${item.qty}',
                      key: ValueKey(item.qty),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)))),
          InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                cart.setQty(item, item.qty + 1);
              },
              borderRadius: BorderRadius.all(r4),
              child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.add, size: 14, color: C.ink))),
        ]));
  }
}

class _CFooter extends StatelessWidget {
  final CartManager cart;
  const _CFooter({required this.cart});
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        decoration: BoxDecoration(color: C.card, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ]),
        child: SafeArea(
            child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Subtotal (${cart.count} art.)',
                  style: const TextStyle(color: C.muted, fontSize: 13)),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(cart.dtotal,
                      key: ValueKey(cart.total),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: C.ink))),
            ]),
            const Text('+ Envío GRATIS',
                style: TextStyle(color: C.blue, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          AB(
            label: 'Proceder al pago',
            bg: C.yellow,
            icon: Icons.lock_outline,
            onTap: () {
              Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(providers: [
                            BlocProvider.value(value: ctx.read<OBloc>())
                          ], child: CheckoutScreen(cart: cart))));
            },
          ),
          const SizedBox(height: 4),
        ])),
      );
}

// ── Checkout / Payment Simulation ─────────────────────────────
class CheckoutScreen extends StatefulWidget {
  final CartManager cart;
  const CheckoutScreen({super.key, required this.cart});
  @override
  State<CheckoutScreen> createState() => _CheckoutState();
}

class _CheckoutState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0; // 0=address 1=payment 2=review

  // Address
  final _name = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _zip = TextEditingController();
  String _country = 'México';

  // Card
  final _cardNum = TextEditingController();
  final _cardName = TextEditingController();
  final _cardExpiry = TextEditingController();
  final _cardCvv = TextEditingController();
  int _selectedCard = -1; // -1 = nueva, 0+ = guardada

  final _savedCards = const [
    SavedCard(
        last4: '4242', brand: 'Visa', holder: 'Usuario Demo', expiry: '12/26'),
    SavedCard(
        last4: '5100',
        brand: 'Mastercard',
        holder: 'Usuario Demo',
        expiry: '08/25'),
  ];

  bool _processing = false;

  @override
  void dispose() {
    _name.dispose();
    _street.dispose();
    _city.dispose();
    _zip.dispose();
    _cardNum.dispose();
    _cardName.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    super.dispose();
  }

  String get _addressFull =>
      '${_name.text}, ${_street.text}, ${_city.text} ${_zip.text}, $_country';
  String get _cardLast4 => _selectedCard >= 0
      ? _savedCards[_selectedCard].last4
      : (_cardNum.text.length >= 4
          ? _cardNum.text.substring(_cardNum.text.length - 4)
          : '????');

  Future<void> _placeOrder() async {
    setState(() => _processing = true);
    // Simulación de procesamiento de pago
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    context.read<OBloc>().add(PlaceOrder(
          items: widget.cart.items,
          total: widget.cart.total,
          address: _addressFull,
          cardLast4: _cardLast4,
        ));
    widget.cart.clear();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const _OrderSuccessScreen()),
        (r) => false);
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(title: const Text('Finalizar compra')),
        body: Column(children: [
          // Progress stepper
          Container(
              color: C.card,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Step(
                    n: 1,
                    label: 'Dirección',
                    active: _step >= 0,
                    done: _step > 0),
                _StepLine(done: _step > 0),
                _Step(n: 2, label: 'Pago', active: _step >= 1, done: _step > 1),
                _StepLine(done: _step > 1),
                _Step(n: 3, label: 'Revisar', active: _step >= 2, done: false),
              ])),
          Expanded(
              child: Form(
                  key: _formKey,
                  child: IndexedStack(index: _step, children: [
                    _AddressStep(
                        name: _name,
                        street: _street,
                        city: _city,
                        zip: _zip,
                        country: _country,
                        onCountryChanged: (v) => setState(() => _country = v)),
                    _PaymentStep(
                        savedCards: _savedCards,
                        selected: _selectedCard,
                        onSelect: (i) => setState(() => _selectedCard = i),
                        cardNum: _cardNum,
                        cardName: _cardName,
                        expiry: _cardExpiry,
                        cvv: _cardCvv),
                    _ReviewStep(
                        cart: widget.cart,
                        address: _addressFull,
                        card: _selectedCard >= 0
                            ? _savedCards[_selectedCard]
                            : null,
                        cardLast4: _cardLast4),
                  ]))),
          // Bottom button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            decoration: BoxDecoration(color: C.card, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3))
            ]),
            child: SafeArea(
                child: Column(children: [
              if (_step == 2)
                Text('Total: ${widget.cart.dtotal}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: C.ink)),
              const SizedBox(height: 10),
              AB(
                label: _step == 2
                    ? (_processing
                        ? 'Procesando...'
                        : 'Confirmar pedido \$${widget.cart.total.toStringAsFixed(2)}')
                    : 'Continuar',
                bg: _step == 2 ? C.orange : C.yellow,
                fg: _step == 2 ? Colors.white : C.ink,
                icon: _step == 2 ? Icons.lock_outline : Icons.arrow_forward,
                loading: _processing,
                onTap: _processing
                    ? null
                    : () {
                        if (_step < 2) {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _step++);
                        } else {
                          _placeOrder();
                        }
                      },
              ),
              const SizedBox(height: 4),
            ])),
          ),
        ]),
      );
}

class _Step extends StatelessWidget {
  final int n;
  final String label;
  final bool active, done;
  const _Step(
      {required this.n,
      required this.label,
      required this.active,
      required this.done});
  @override
  Widget build(BuildContext ctx) => Column(children: [
        AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? C.green
                    : active
                        ? C.orange
                        : C.line),
            child: Center(
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text('$n',
                        style: TextStyle(
                            color: active ? Colors.white : C.muted,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)))),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: active ? C.ink : C.muted,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ]);
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});
  @override
  Widget build(BuildContext ctx) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 2,
          color: done ? C.green : C.line));
}

class _AddressStep extends StatelessWidget {
  final TextEditingController name, street, city, zip;
  final String country;
  final ValueChanged<String> onCountryChanged;
  const _AddressStep(
      {required this.name,
      required this.street,
      required this.city,
      required this.zip,
      required this.country,
      required this.onCountryChanged});
  @override
  Widget build(BuildContext ctx) =>
      ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Dirección de envío',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: C.ink)),
        const SizedBox(height: 16),
        AF(
            ctrl: name,
            hint: 'Nombre completo',
            lead: const Icon(Icons.person_outline),
            validate: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null),
        const SizedBox(height: 12),
        AF(
            ctrl: street,
            hint: 'Calle y número',
            lead: const Icon(Icons.home_outlined),
            validate: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: AF(
                  ctrl: city,
                  hint: 'Ciudad',
                  validate: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null)),
          const SizedBox(width: 12),
          SizedBox(
              width: 110,
              child: AF(
                  ctrl: zip,
                  hint: 'C.P.',
                  type: TextInputType.number,
                  validate: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null)),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: country,
          decoration: InputDecoration(
              labelText: 'País',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(r4),
                  borderSide: const BorderSide(color: C.line)),
              filled: true,
              fillColor: Colors.white),
          items: [
            'México',
            'Colombia',
            'Argentina',
            'España',
            'Chile',
            'Estados Unidos'
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) {
            if (v != null) onCountryChanged(v);
          },
        ),
      ]);
}

class _PaymentStep extends StatelessWidget {
  final List<SavedCard> savedCards;
  final int selected;
  final ValueChanged<int> onSelect;
  final TextEditingController cardNum, cardName, expiry, cvv;
  const _PaymentStep(
      {required this.savedCards,
      required this.selected,
      required this.onSelect,
      required this.cardNum,
      required this.cardName,
      required this.expiry,
      required this.cvv});

  @override
  Widget build(BuildContext ctx) =>
      ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Método de pago',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: C.ink)),
        const SizedBox(height: 14),
        // Tarjetas guardadas
        ...savedCards.asMap().entries.map((e) => _SavedCardTile(
            card: e.value,
            selected: selected == e.key,
            onTap: () => onSelect(e.key))),
        // Nueva tarjeta
        GestureDetector(
          onTap: () => onSelect(-1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.all(r8),
                border: Border.all(
                    color: selected == -1 ? C.orange : C.line,
                    width: selected == -1 ? 2 : 1)),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: C.bg, borderRadius: BorderRadius.all(r8)),
                  child: const Icon(Icons.add_card_outlined,
                      color: C.blue, size: 20)),
              const SizedBox(width: 12),
              const Text('Nueva tarjeta',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              const Spacer(),
              if (selected == -1)
                const Icon(Icons.radio_button_checked,
                    color: C.orange, size: 20)
              else
                const Icon(Icons.radio_button_off, color: C.muted, size: 20),
            ]),
          ),
        ),
        // Formulario nueva tarjeta
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: selected == -1
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: C.card,
                  borderRadius: BorderRadius.all(r8),
                  border: Border.all(color: C.line)),
              child: Column(children: [
                AF(
                    ctrl: cardNum,
                    hint: 'Número de tarjeta',
                    type: TextInputType.number,
                    lead: const Icon(Icons.credit_card),
                    maxLen: 16,
                    validate: (v) =>
                        selected == -1 && (v == null || v.length < 12)
                            ? 'Número inválido'
                            : null),
                const SizedBox(height: 12),
                AF(
                    ctrl: cardName,
                    hint: 'Nombre en la tarjeta',
                    lead: const Icon(Icons.person_outline),
                    validate: (v) =>
                        selected == -1 && (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: AF(
                          ctrl: expiry,
                          hint: 'MM/AA',
                          type: TextInputType.number,
                          validate: (v) =>
                              selected == -1 && (v == null || v.length < 4)
                                  ? 'Inválido'
                                  : null)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: AF(
                          ctrl: cvv,
                          hint: 'CVV',
                          type: TextInputType.number,
                          maxLen: 4,
                          validate: (v) =>
                              selected == -1 && (v == null || v.length < 3)
                                  ? 'Inválido'
                                  : null)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.lock_outline, size: 14, color: C.muted),
                  const SizedBox(width: 6),
                  const Text('Tus datos están encriptados y seguros',
                      style: TextStyle(fontSize: 11, color: C.muted))
                ]),
              ])),
          secondChild: const SizedBox.shrink(),
        ),
      ]);
}

class _SavedCardTile extends StatelessWidget {
  final SavedCard card;
  final bool selected;
  final VoidCallback onTap;
  const _SavedCardTile(
      {required this.card, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.all(r8),
              border: Border.all(
                  color: selected ? C.orange : C.line,
                  width: selected ? 2 : 1)),
          child: Row(children: [
            Container(
                width: 44,
                height: 28,
                decoration: BoxDecoration(
                    color: selected ? C.orange.withOpacity(0.1) : C.bg,
                    borderRadius: BorderRadius.all(r4)),
                child: Center(
                    child: Text(card.brand[0],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected ? C.orange : C.muted)))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${card.brand} •••• ${card.last4}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${card.holder}  •  Vence ${card.expiry}',
                      style: const TextStyle(fontSize: 12, color: C.muted)),
                ])),
            if (selected)
              const Icon(Icons.radio_button_checked, color: C.orange, size: 20)
            else
              const Icon(Icons.radio_button_off, color: C.muted, size: 20),
          ]),
        ),
      );
}

class _ReviewStep extends StatelessWidget {
  final CartManager cart;
  final String address;
  final SavedCard? card;
  final String cardLast4;
  const _ReviewStep(
      {required this.cart,
      required this.address,
      this.card,
      required this.cardLast4});
  @override
  Widget build(BuildContext ctx) =>
      ListView(padding: const EdgeInsets.all(16), children: [
        _ReviewSection(
            title: 'Productos (${cart.count})',
            child: Column(
                children: cart.items
                    .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[50],
                              padding: const EdgeInsets.all(4),
                              child: CachedNetworkImage(
                                  imageUrl: item.product.image,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) =>
                                      const SizedBox.shrink(),
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(item.product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13, color: C.ink)),
                                Text('Cant: ${item.qty}  •  ${item.product.dp}',
                                    style: const TextStyle(
                                        fontSize: 12, color: C.muted)),
                              ])),
                          Text(item.dsub,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ])))
                    .toList())),
        const SizedBox(height: 12),
        _ReviewSection(
            title: 'Dirección de envío',
            child: Text(address,
                style: const TextStyle(
                    fontSize: 13, color: C.muted, height: 1.5))),
        const SizedBox(height: 12),
        _ReviewSection(
            title: 'Método de pago',
            child: Row(children: [
              const Icon(Icons.credit_card, size: 20, color: C.muted),
              const SizedBox(width: 8),
              Text(
                  card != null
                      ? '${card!.brand} •••• ${card!.last4}'
                      : 'Tarjeta •••• $cardLast4',
                  style: const TextStyle(fontSize: 13, color: C.ink)),
            ])),
        const SizedBox(height: 12),
        _ReviewSection(
            title: 'Resumen del pedido',
            child: Column(children: [
              _SumRow(label: 'Subtotal', val: cart.dtotal),
              const _SumRow(label: 'Envío', val: 'GRATIS'),
              const _SumRow(label: 'Impuestos', val: '\$0.00'),
              const Divider(height: 16, color: C.line),
              _SumRow(label: 'Total', val: cart.dtotal, bold: true),
            ])),
        const SizedBox(height: 8),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: C.green.withOpacity(0.08),
                borderRadius: BorderRadius.all(r8),
                border: Border.all(color: C.green.withOpacity(0.2))),
            child: const Row(children: [
              Icon(Icons.verified_user_outlined, color: C.green, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Compra 100% segura. Garantía de devolución de 30 días.',
                      style:
                          TextStyle(fontSize: 12, color: C.green, height: 1.4)))
            ])),
      ]);
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _ReviewSection({required this.title, required this.child});
  @override
  Widget build(BuildContext ctx) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.all(r8),
          border: Border.all(color: C.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: C.ink)),
        const SizedBox(height: 10),
        child,
      ]));
}

class _SumRow extends StatelessWidget {
  final String label, val;
  final bool bold;
  const _SumRow({required this.label, required this.val, this.bold = false});
  @override
  Widget build(BuildContext ctx) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: bold ? C.ink : C.muted,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(val,
            style: TextStyle(
                fontSize: 13,
                color: bold ? C.ink : C.muted,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ]));
}

class _OrderSuccessScreen extends StatelessWidget {
  const _OrderSuccessScreen();
  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.card,
        body: SafeArea(
            child: Center(
                child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (_, v, child) =>
                              Transform.scale(scale: v, child: child),
                          child: Container(
                              width: 90,
                              height: 90,
                              decoration: const BoxDecoration(
                                  color: C.green, shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 50))),
                      const SizedBox(height: 24),
                      const Text('¡Pedido confirmado!',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: C.ink)),
                      const SizedBox(height: 10),
                      const Text(
                          'Tu pedido ha sido procesado exitosamente.\nRecibirás una confirmación pronto.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: C.muted, height: 1.5)),
                      const SizedBox(height: 32),
                      AB(
                          label: 'Ver mis pedidos',
                          bg: C.yellow,
                          icon: Icons.receipt_long_outlined,
                          onTap: () => Navigator.pushAndRemoveUntil(
                              ctx,
                              MaterialPageRoute(builder: (_) => const Shell()),
                              (r) => false)),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: () => Navigator.pushAndRemoveUntil(
                              ctx,
                              MaterialPageRoute(builder: (_) => const Shell()),
                              (r) => false),
                          child: const Text('Seguir comprando')),
                    ])))),
      );
}

// ── Orders Screen ──────────────────────────────────────────────
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OScreenState();
}

class _OScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OBloc>().add(LoadOrders());
    });
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(title: const Text('Mis pedidos'), actions: [
          IconButton(
              icon: const Icon(Icons.refresh_outlined, color: Colors.white),
              onPressed: () => ctx.read<OBloc>().add(LoadOrders())),
        ]),
        body: BlocBuilder<OBloc, OSt>(builder: (ctx, st) {
          if (st is OIdle || st is OBusy || st is ODone)
            return const Center(
                child: CircularProgressIndicator(color: C.orange));
          if (st is OFail)
            return ErrBox(
                msg: st.msg, retry: () => ctx.read<OBloc>().add(LoadOrders()));
          if (st is OReady) {
            if (st.orders.isEmpty)
              return const Empty(
                  icon: Icons.receipt_long_outlined,
                  title: 'Sin pedidos todavía',
                  sub: 'Tus compras aparecerán aquí');
            return RefreshIndicator(
                color: C.orange,
                onRefresh: () async {
                  ctx.read<OBloc>().add(LoadOrders());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: st.orders.length,
                    itemBuilder: (ctx, i) => Slide(
                        delay: Duration(milliseconds: i * 50),
                        child: _OCard(o: st.orders[i]))));
          }
          return const SizedBox.shrink();
        }),
      );
}

class _OCard extends StatelessWidget {
  final Order o;
  const _OCard({required this.o});
  @override
  Widget build(BuildContext ctx) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.all(r8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: C.navy.withOpacity(0.04),
                  borderRadius: const BorderRadius.vertical(top: r8)),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('PEDIDO ${o.sid}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: C.ink,
                              letterSpacing: 0.5)),
                      Text(o.fdate,
                          style: const TextStyle(fontSize: 11, color: C.muted)),
                      const SizedBox(height: 2),
                      Text(
                          '${o.items.length} producto${o.items.length != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 11, color: C.muted)),
                    ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(o.dtotal,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: C.ink)),
                  const SizedBox(height: 4),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: o.status.color.withOpacity(0.12),
                          borderRadius: BorderRadius.all(r99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(o.status.icon, size: 11, color: o.status.color),
                        const SizedBox(width: 4),
                        Text(o.status.label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: o.status.color)),
                      ])),
                ]),
              ])),
          if (o.items.isNotEmpty) ...[
            const Divider(height: 1, color: C.line),
            Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    children: o.items
                        .take(3)
                        .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              Container(
                                  width: 54,
                                  height: 54,
                                  color: Colors.grey[50],
                                  padding: const EdgeInsets.all(4),
                                  child: CachedNetworkImage(
                                      imageUrl: item.product.image,
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) =>
                                          const SizedBox.shrink(),
                                      errorWidget: (_, __, ___) => const Icon(
                                          Icons.broken_image_outlined,
                                          color: Colors.grey))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(item.product.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12.5, color: C.ink)),
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      Text(item.product.dp,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                              color: C.bg,
                                              borderRadius:
                                                  BorderRadius.all(r4),
                                              border:
                                                  Border.all(color: C.line)),
                                          child: Text('x${item.qty}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: C.muted)))
                                    ]),
                                  ])),
                            ])))
                        .toList())),
            if (o.items.length > 3) ...[
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Text(
                      '+ ${o.items.length - 3} producto${o.items.length - 3 != 1 ? 's' : ''} más',
                      style: const TextStyle(fontSize: 12, color: C.blue)))
            ],
          ],
          const Divider(height: 1, color: C.line),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: C.line),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(r4)),
                            padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text('Ver detalle',
                            style: TextStyle(fontSize: 12, color: C.ink)))),
                const SizedBox(width: 8),
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: C.yellow,
                            foregroundColor: C.ink,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(r4)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0),
                        child: const Text('Comprar de nuevo',
                            style: TextStyle(fontSize: 12)))),
              ])),
        ]),
      );
}

// ── Profile Screen ─────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<ABloc>().state;
    final email = st is AOk ? (st.email ?? 'Usuario') : 'Usuario';
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Slide(
            child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: C.card, borderRadius: BorderRadius.all(r8)),
                child: Row(children: [
                  CircleAvatar(
                      radius: 34,
                      backgroundColor: C.navy,
                      child: Text(email[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(email,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: C.ink)),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.verified, size: 13, color: C.prime),
                          const SizedBox(width: 4),
                          const Text('Cuenta verificada',
                              style: TextStyle(fontSize: 12, color: C.prime))
                        ]),
                      ])),
                  TextButton(
                      onPressed: () =>
                          _snack(ctx, 'Editar perfil próximamente'),
                      child:
                          const Text('Editar', style: TextStyle(fontSize: 13))),
                ]))),
        const SizedBox(height: 12),
        Slide(
            delay: const Duration(milliseconds: 60),
            child: _PSec(title: 'PEDIDOS Y COMPRAS', tiles: [
              _PTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Mis pedidos',
                  sub: 'Ver historial de compras',
                  onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                              value: ctx.read<OBloc>(),
                              child: const _OrdersPage())))),
              _PTile(
                  icon: Icons.star_outline,
                  label: 'Mis reseñas',
                  sub: 'Opiniones publicadas',
                  onTap: () => _snack(ctx, 'Próximamente disponible')),
              _PTile(
                  icon: Icons.favorite_outline,
                  label: 'Lista de deseos',
                  sub: 'Productos guardados',
                  onTap: () => _snack(ctx, 'Próximamente disponible')),
            ])),
        const SizedBox(height: 8),
        Slide(
            delay: const Duration(milliseconds: 100),
            child: _PSec(title: 'CUENTA', tiles: [
              _PTile(
                  icon: Icons.location_on_outlined,
                  label: 'Direcciones',
                  sub: 'Gestionar direcciones de envío',
                  onTap: () => _showAddressDialog(ctx)),
              _PTile(
                  icon: Icons.credit_card_outlined,
                  label: 'Métodos de pago',
                  sub: 'Tarjetas y métodos',
                  onTap: () => _showPaymentDialog(ctx)),
              _PTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notificaciones',
                  sub: 'Configurar alertas',
                  onTap: () => _snack(ctx, 'Notificaciones: activadas')),
              _PTile(
                  icon: Icons.language_outlined,
                  label: 'Idioma y región',
                  sub: 'Español — México',
                  onTap: () => _snack(ctx, 'Idioma: Español')),
            ])),
        const SizedBox(height: 8),
        Slide(
            delay: const Duration(milliseconds: 140),
            child: _PSec(title: 'AYUDA', tiles: [
              _PTile(
                  icon: Icons.help_outline,
                  label: 'Centro de ayuda',
                  sub: 'FAQ y guías de uso',
                  onTap: () => _snack(ctx, 'Abriendo ayuda...')),
              _PTile(
                  icon: Icons.chat_outlined,
                  label: 'Soporte al cliente',
                  sub: 'Chat 24/7',
                  onTap: () => _snack(ctx, 'Iniciando chat...')),
              _PTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacidad y seguridad',
                  sub: 'Gestionar datos',
                  onTap: () => _snack(ctx, 'Próximamente disponible')),
            ])),
        const SizedBox(height: 16),
        Slide(
            delay: const Duration(milliseconds: 180),
            child: AB(
                label: 'Cerrar sesión',
                icon: Icons.logout,
                bg: C.danger.withOpacity(0.08),
                fg: C.danger,
                onTap: () => _confirmLogout(ctx))),
        const SizedBox(height: 8),
        const Center(
            child: Text('Amazon 2026 v1.0.0',
                style: TextStyle(fontSize: 11, color: C.muted))),
        const SizedBox(height: 20),
      ]),
    );
  }

  void _snack(BuildContext ctx, String msg) =>
      ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  void _confirmLogout(BuildContext ctx) => showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
                title: const Text('¿Cerrar sesión?'),
                content: const Text('Se cerrará tu sesión actual.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Cerrar sesión',
                          style: TextStyle(color: C.danger)))
                ],
              )).then((ok) {
        if (ok == true) ctx.read<ABloc>().add(DoLogout());
      });

  void _showAddressDialog(BuildContext ctx) => showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
            title: const Text('Mis direcciones'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              _AdrTile(
                  icon: Icons.home_outlined,
                  label: 'Casa',
                  address: 'Calle Principal 123, CDMX'),
              _AdrTile(
                  icon: Icons.work_outlined,
                  label: 'Trabajo',
                  address: 'Av. Reforma 456, CDMX'),
              TextButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar dirección')),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'))
            ],
          ));

  void _showPaymentDialog(BuildContext ctx) => showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
            title: const Text('Métodos de pago'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              _PayTile(brand: 'Visa', last4: '4242', expiry: '12/26'),
              _PayTile(brand: 'Mastercard', last4: '5100', expiry: '08/25'),
              TextButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar tarjeta')),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'))
            ],
          ));
}

class _AdrTile extends StatelessWidget {
  final IconData icon;
  final String label, address;
  const _AdrTile(
      {required this.icon, required this.label, required this.address});
  @override
  Widget build(BuildContext ctx) => ListTile(
      dense: true,
      leading: Icon(icon, color: C.blue, size: 20),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(address, style: const TextStyle(fontSize: 12)));
}

class _PayTile extends StatelessWidget {
  final String brand, last4, expiry;
  const _PayTile(
      {required this.brand, required this.last4, required this.expiry});
  @override
  Widget build(BuildContext ctx) => ListTile(
      dense: true,
      leading: const Icon(Icons.credit_card, color: C.blue, size: 20),
      title: Text('$brand •••• $last4',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text('Vence $expiry', style: const TextStyle(fontSize: 12)));
}

// Orders page (from profile)
class _OrdersPage extends StatefulWidget {
  const _OrdersPage();
  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<OBloc>().add(LoadOrders());
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(title: const Text('Mis pedidos'), actions: [
          IconButton(
              icon: const Icon(Icons.refresh_outlined, color: Colors.white),
              onPressed: () => ctx.read<OBloc>().add(LoadOrders()))
        ]),
        body: BlocBuilder<OBloc, OSt>(builder: (ctx, st) {
          if (st is OIdle || st is OBusy || st is ODone)
            return const Center(
                child: CircularProgressIndicator(color: C.orange));
          if (st is OFail)
            return ErrBox(
                msg: st.msg, retry: () => ctx.read<OBloc>().add(LoadOrders()));
          if (st is OReady) {
            if (st.orders.isEmpty)
              return const Empty(
                  icon: Icons.receipt_long_outlined,
                  title: 'Sin pedidos todavía',
                  sub: 'Realiza tu primera compra');
            return RefreshIndicator(
                color: C.orange,
                onRefresh: () async {
                  ctx.read<OBloc>().add(LoadOrders());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: st.orders.length,
                    itemBuilder: (ctx, i) => Slide(
                        delay: Duration(milliseconds: i * 50),
                        child: _OCard(o: st.orders[i]))));
          }
          return const SizedBox.shrink();
        }),
      );
}

class _PSec extends StatelessWidget {
  final String title;
  final List<_PTile> tiles;
  const _PSec({required this.title, required this.tiles});
  @override
  Widget build(BuildContext ctx) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: C.muted,
                    letterSpacing: 0.6))),
        Container(
            decoration: BoxDecoration(
                color: C.card, borderRadius: BorderRadius.all(r8)),
            child: Column(
                children: tiles
                    .asMap()
                    .entries
                    .map((e) => Column(children: [
                          e.value,
                          if (e.key < tiles.length - 1)
                            const Divider(height: 1, indent: 52)
                        ]))
                    .toList())),
      ]);
}

class _PTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final VoidCallback? onTap;
  const _PTile(
      {required this.icon, required this.label, required this.sub, this.onTap});
  @override
  Widget build(BuildContext ctx) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.all(r8),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: C.navy.withOpacity(0.07),
                      borderRadius: BorderRadius.all(r8)),
                  child: Icon(icon, color: C.navy, size: 20)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: C.ink)),
                    const SizedBox(height: 1),
                    Text(sub,
                        style: const TextStyle(fontSize: 12, color: C.muted)),
                  ])),
              const Icon(Icons.chevron_right, color: C.muted, size: 20),
            ])),
      ));
}

// ── Main ───────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light));
  await Supabase.initialize(
    url: 'https://naiwccpffldjpvcohidp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5haXdjY3BmZmxkanB2Y29oaWRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4ODAzODIsImV4cCI6MjA4NzQ1NjM4Mn0.S64yoFU8_IgYSZBjKPpWBVeF8hYoFffR0QVhQCe2J68',
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext ctx) {
    final authRepo = AuthRepo();
    final productRepo = ProductRepo();
    final orderRepo = OrderRepo();
    final reviewRepo = ReviewRepo();
    final cart = CartManager();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cart),
        BlocProvider(create: (_) => ABloc(authRepo)),
        BlocProvider(create: (_) => PBloc(productRepo)),
        BlocProvider(create: (_) => OBloc(orderRepo, productRepo, authRepo)),
        BlocProvider(create: (_) => RBloc(reviewRepo, authRepo)),
      ],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Amazon 2026',
          theme: appTheme,
          home: const Root()),
    );
  }
}
