import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/exceptions.dart';
import '../../models/review.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/review_repository.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();
  @override List<Object?> get props => [];
}

class LoadReviews extends ReviewEvent {
  final int productId;
  const LoadReviews(this.productId);
  @override List<Object?> get props => [productId];
}

class PostReview extends ReviewEvent {
  final int    productId;
  final double rating;
  final String comment;
  const PostReview({required this.productId, required this.rating, required this.comment});
  @override List<Object?> get props => [productId, rating, comment];
}

class DeleteReview extends ReviewEvent {
  final String reviewId;
  final int    productId;
  const DeleteReview(this.reviewId, this.productId);
  @override List<Object?> get props => [reviewId];
}

abstract class ReviewState extends Equatable {
  const ReviewState();
  @override List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}
class ReviewLoading  extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final List<Review> reviews;
  final bool         userHasReviewed;

  const ReviewLoaded(this.reviews, {this.userHasReviewed = false});

  double get averageRating => reviews.isEmpty
      ? 0
      : reviews.fold(0.0, (s, r) => s + r.rating) / reviews.length;

  @override List<Object?> get props => [reviews, userHasReviewed];
}

class ReviewError extends ReviewState {
  final String message;
  const ReviewError(this.message);
  @override List<Object?> get props => [message];
}

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _reviewRepo;
  final AuthRepository   _authRepo;

  ReviewBloc(this._reviewRepo, this._authRepo) : super(ReviewInitial()) {
    on<LoadReviews>(_onLoad);
    on<PostReview>(_onPost);
    on<DeleteReview>(_onDelete);
  }

  Future<void> _onLoad(LoadReviews event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    try {
      final reviews = await _reviewRepo.getProductReviews(event.productId);
      final userId  = _authRepo.currentUser?.id;
      final hasReviewed = userId != null
          ? await _reviewRepo.userHasReviewed(userId, event.productId)
          : false;
      emit(ReviewLoaded(reviews, userHasReviewed: hasReviewed));
    } on AppException catch (e) {
      emit(ReviewError(e.message));
    }
  }

  Future<void> _onPost(PostReview event, Emitter<ReviewState> emit) async {
    final user = _authRepo.currentUser;
    if (user == null) return;
    emit(ReviewLoading());
    try {
      await _reviewRepo.addReview(
        userId:    user.id,
        userEmail: user.email ?? 'Usuario',
        productId: event.productId,
        rating:    event.rating,
        comment:   event.comment,
      );
      add(LoadReviews(event.productId));
    } on AppException catch (e) {
      emit(ReviewError(e.message));
    }
  }

  Future<void> _onDelete(DeleteReview event, Emitter<ReviewState> emit) async {
    try {
      await _reviewRepo.deleteReview(event.reviewId);
      add(LoadReviews(event.productId));
    } on AppException catch (e) {
      emit(ReviewError(e.message));
    }
  }
}
