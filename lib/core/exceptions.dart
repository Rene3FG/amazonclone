abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

class AppAuthException    extends AppException { const AppAuthException(super.m); }
class NetworkException    extends AppException { const NetworkException(super.m); }
class CartException       extends AppException { const CartException(super.m); }
class OrderException      extends AppException { const OrderException(super.m); }
class ReviewException     extends AppException { const ReviewException(super.m); }
