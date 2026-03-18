# Amazon 2026 — Flutter Clone

Clon de Amazon construido con Flutter, BLoC y Supabase.

## Stack

- **Flutter** 3.x + Dart 3
- **BLoC** — gestión de estado (AuthBloc, ProductBloc, OrderBloc, ReviewBloc, WishlistBloc)
- **Supabase** — base de datos, autenticación y almacenamiento
- **FakeStore API** — catálogo de productos
- **Provider** — CartService (estado del carrito)

## Estructura del proyecto

```
lib/
├── main.dart                  ← Entry point + providers + shell
├── core/
│   ├── theme.dart             ← Colores, tema, constantes
│   └── exceptions.dart        ← Excepciones tipadas
├── models/
│   ├── product.dart
│   ├── cart_item.dart
│   ├── order.dart             ← Order, OrderItem, SavedCard, ShippingAddress
│   └── review.dart
├── repositories/
│   ├── auth_repository.dart
│   ├── product_repository.dart
│   ├── order_repository.dart
│   ├── review_repository.dart
│   └── wishlist_repository.dart
├── blocs/
│   ├── auth/auth_bloc.dart
│   ├── product/product_bloc.dart
│   ├── order/order_bloc.dart
│   ├── review/review_bloc.dart
│   └── wishlist/wishlist_bloc.dart
├── services/
│   └── cart_service.dart      ← CartService (ChangeNotifier)
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── detail_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── orders_screen.dart
│   └── profile_screen.dart
└── widgets/
    └── shared_widgets.dart    ← AppButton, AppTextField, ProductImage, etc.
```

## Setup

### 1. Supabase

1. Ve al **SQL Editor** de tu proyecto Supabase.
2. Ejecuta el archivo `supabase_setup.sql` completo.
3. Esto crea las tablas, activa RLS, agrega índices y funciones.

### 2. Flutter

```bash
flutter pub get
flutter run
```

### 3. Credenciales

Las credenciales de Supabase ya están en `main.dart`.  
Para producción, muévalas a variables de entorno:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Y en `main.dart`:

```dart
await Supabase.initialize(
  url:     const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

## Funcionalidades

- ✅ Login / registro / Google Sign-In
- ✅ Recordar credenciales (flutter_secure_storage)
- ✅ Catálogo de productos con filtros por categoría
- ✅ Búsqueda en tiempo real
- ✅ Ofertas del día y mejor valorados
- ✅ Carrito con sync en Supabase
- ✅ Checkout en 3 pasos (dirección → pago → revisión)
- ✅ Historial de pedidos
- ✅ Reseñas y calificaciones por producto
- ✅ Lista de deseos (wishlist) con corazón en cada producto
- ✅ Animaciones (slide-in, press effect, hero images)
- ✅ Pull-to-refresh en todas las listas
- ✅ Swipe-to-delete en el carrito
- ✅ Pantalla de éxito tras compra
- ✅ RLS activado en todas las tablas Supabase
- ✅ Índices de rendimiento en Supabase

## Mejoras de seguridad implementadas

| Problema original | Solución |
|---|---|
| Sin RLS en ninguna tabla | RLS activado en cart, orders, order_items, reviews, wishlist |
| N+1 queries en OrderRepo | Batch query: todos los order_items en una sola consulta |
| Fetch individual en CartManager | Batch HTTP paralelo con Future.wait() |
| Todo en main.dart (4,410 líneas) | Arquitectura en capas: repos, blocs, screens, widgets |
| Nombres crípticos (C, AB, AF...) | Nombres descriptivos: AppColors, AppButton, AppTextField... |
