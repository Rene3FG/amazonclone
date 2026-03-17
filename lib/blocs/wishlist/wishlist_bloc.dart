import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/wishlist_repository.dart';

abstract class WishlistEvent extends Equatable {
  const WishlistEvent();
  @override List<Object?> get props => [];
}

class LoadWishlist   extends WishlistEvent {}

class ToggleWishlist extends WishlistEvent {
  final int productId;
  const ToggleWishlist(this.productId);
  @override List<Object?> get props => [productId];
}

abstract class WishlistState extends Equatable {
  const WishlistState();
  @override List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<int> productIds;
  const WishlistLoaded(this.productIds);
  bool contains(int id) => productIds.contains(id);
  @override List<Object?> get props => [productIds];
}

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final WishlistRepository _repo;
  final AuthRepository     _authRepo;

  WishlistBloc(this._repo, this._authRepo) : super(WishlistInitial()) {
    on<LoadWishlist>(_onLoad);
    on<ToggleWishlist>(_onToggle);
  }

  Future<void> _onLoad(LoadWishlist event, Emitter<WishlistState> emit) async {
    final userId = _authRepo.currentUser?.id;
    if (userId == null) { emit(const WishlistLoaded([])); return; }
    final ids = await _repo.getWishlistProductIds(userId);
    emit(WishlistLoaded(ids));
  }

  Future<void> _onToggle(ToggleWishlist event, Emitter<WishlistState> emit) async {
    final userId  = _authRepo.currentUser?.id;
    if (userId == null) return;

    final current = state is WishlistLoaded
        ? List<int>.from((state as WishlistLoaded).productIds)
        : <int>[];

    if (current.contains(event.productId)) {
      current.remove(event.productId);
      emit(WishlistLoaded(current));
      await _repo.removeFromWishlist(userId, event.productId);
    } else {
      current.add(event.productId);
      emit(WishlistLoaded(current));
      await _repo.addToWishlist(userId, event.productId);
    }
  }
}
