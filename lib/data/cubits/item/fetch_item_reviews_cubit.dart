import 'package:eClassify/data/model/seller_ratings_model.dart';
import 'package:eClassify/data/repositories/item_reviews_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchItemReviewsState {}

class FetchItemReviewsInitial extends FetchItemReviewsState {}

class FetchItemReviewsInProgress extends FetchItemReviewsState {}

class FetchItemReviewsSuccess extends FetchItemReviewsState {
  final List<UserRatings> reviews;
  final int total;
  final int currentPage;
  final bool hasMoreData;
  final bool isLoadingMore;

  FetchItemReviewsSuccess({
    required this.reviews,
    required this.total,
    required this.currentPage,
    required this.hasMoreData,
    this.isLoadingMore = false,
  });

  FetchItemReviewsSuccess copyWith({
    List<UserRatings>? reviews,
    int? total,
    int? currentPage,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return FetchItemReviewsSuccess(
      reviews: reviews ?? this.reviews,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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

  Future<void> fetchItemReviews({required int itemId}) async {
    try {
      emit(FetchItemReviewsInProgress());

      final result = await _repository.fetchItemReviews(itemId: itemId);

      if (result['error'] == true) {
        emit(FetchItemReviewsFailure(result['message']));
        return;
      }

      List<UserRatings> reviews = [];
      int total = 0;

      if (result['data'] != null) {
        // Extract reviews from response - correct nested structure
        if (result['data']['reviews'] != null &&
            result['data']['reviews']['data'] != null) {
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
        currentPage: 1,
        hasMoreData: total > reviews.length,
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
          if (result['data']['reviews'] != null &&
              result['data']['reviews']['data'] != null) {
            for (var review in result['data']['reviews']['data']) {
              newReviews.add(UserRatings.fromJson(review));
            }

            // Update total if provided
            total = result['data']['reviews']['total'] ?? total;
          }
        }

        // Combine existing and new reviews
        List<UserRatings> updatedReviews = [
          ...currentState.reviews,
          ...newReviews
        ];

        emit(FetchItemReviewsSuccess(
          reviews: updatedReviews,
          total: total,
          currentPage: currentState.currentPage + 1,
          hasMoreData: total > updatedReviews.length,
          isLoadingMore: false,
        ));
      } catch (e) {
        print("Error fetching more reviews: $e");
        if (state is FetchItemReviewsSuccess) {
          emit((state as FetchItemReviewsSuccess)
              .copyWith(isLoadingMore: false));
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
}
