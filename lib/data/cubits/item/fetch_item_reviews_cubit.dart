import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/seller_ratings_model.dart';
import 'package:tlobni/data/repositories/item_reviews_repository.dart';

sealed class FetchItemReviewsState {}

class FetchItemReviewsInitial extends FetchItemReviewsState {}

class FetchItemReviewsInProgress extends FetchItemReviewsState {}

class FetchItemReviewsSuccess extends FetchItemReviewsState {
  final List<UserRatings> reviews;
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasMoreData;
  final bool isLoadingMore;
  final double averageRating;

  FetchItemReviewsSuccess({
    required this.reviews,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.hasMoreData,
    required this.averageRating,
    this.isLoadingMore = false,
  });

  FetchItemReviewsSuccess copyWith({
    List<UserRatings>? reviews,
    int? total,
    int? currentPage,
    int? lastPage,
    bool? hasMoreData,
    bool? isLoadingMore,
    double? averageRating,
  }) {
    return FetchItemReviewsSuccess(
      reviews: reviews ?? this.reviews,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}

class FetchItemReviewsFailure extends FetchItemReviewsState {
  final dynamic error;

  FetchItemReviewsFailure(this.error);
}

class FetchItemReviewsCubit extends Cubit<FetchItemReviewsState> {
  final ItemReviewsRepository _repository = ItemReviewsRepository();

  FetchItemReviewsCubit() : super(FetchItemReviewsInitial());

  Future<void> fetchItemReviews({required int itemId, int page = 0}) async {
    try {
      emit(FetchItemReviewsInProgress());

      final result = await _repository.fetchItemReviews(itemId: itemId, page: page);

      if (result['error'] == true) {
        emit(FetchItemReviewsFailure(result['message']));
        return;
      }

      List<UserRatings> reviews = [];
      int total = 0;

      if (result['data'] != null) {
        // Extract reviews from response - correct nested structure
        if (result['data']['reviews'] != null && result['data']['reviews']['data'] != null) {
          for (var review in result['data']['reviews']['data']) {
            reviews.add(UserRatings.fromJson(review));
          }

          // Extract total from reviews response
          total = result['data']['reviews']['total'] ?? 0;
        }
      }

      emit(FetchItemReviewsSuccess(
        reviews: reviews,
        total: total,
        currentPage: result['data']['reviews']['current_page'],
        lastPage: result['data']['reviews']['last_page'],
        hasMoreData: total > reviews.length,
        averageRating: _getAverageRating(result),
      ));
    } catch (e) {
      print("Error fetching reviews: $e");
      emit(FetchItemReviewsFailure(e));
    }
  }

  Future<void> fetchMoreItemReviews({required int itemId}) async {
    if (state is FetchItemReviewsSuccess) {
      final currentState = state as FetchItemReviewsSuccess;

      if (!currentState.hasMoreData || currentState.isLoadingMore) {
        return;
      }

      try {
        emit(currentState.copyWith(isLoadingMore: true));

        final result = await _repository.fetchItemReviews(
          itemId: itemId,
          page: currentState.currentPage + 1,
        );

        if (result['error'] == true) {
          emit(currentState.copyWith(isLoadingMore: false));
          return;
        }

        List<UserRatings> newReviews = [];
        int total = currentState.total;

        if (result['data'] != null) {
          // Extract reviews from response - correct nested structure
          if (result['data']['reviews'] != null && result['data']['reviews']['data'] != null) {
            for (var review in result['data']['reviews']['data']) {
              newReviews.add(UserRatings.fromJson(review));
            }

            // Update total if provided
            total = result['data']['reviews']['total'] ?? total;
          }
        }

        // Combine existing and new reviews
        List<UserRatings> updatedReviews = [...currentState.reviews, ...newReviews];

        emit(FetchItemReviewsSuccess(
          reviews: updatedReviews,
          total: total,
          currentPage: currentState.currentPage + 1,
          hasMoreData: total > updatedReviews.length,
          lastPage: result['data']['reviews']['last_page'],
          isLoadingMore: false,
          averageRating: _getAverageRating(result),
        ));
      } catch (e) {
        print("Error fetching more reviews: $e");
        if (state is FetchItemReviewsSuccess) {
          emit((state as FetchItemReviewsSuccess).copyWith(isLoadingMore: false));
        }
      }
    }
  }

  bool hasMoreData() {
    if (state is FetchItemReviewsSuccess) {
      return (state as FetchItemReviewsSuccess).hasMoreData;
    }
    return false;
  }

  void updateExpandedState(int index) {
    if (state is FetchItemReviewsSuccess) {
      final currentState = state as FetchItemReviewsSuccess;
      final reviews = List<UserRatings>.from(currentState.reviews);

      // Toggle expanded state
      reviews[index] = reviews[index].copyWith(
        isExpanded: !(reviews[index].isExpanded ?? false),
      );

      emit(currentState.copyWith(reviews: reviews));
    }
  }

  double _getAverageRating(Map<dynamic, dynamic> result) => ((result['data']?['average_rating'] ?? 0) as num).toDouble();
}
