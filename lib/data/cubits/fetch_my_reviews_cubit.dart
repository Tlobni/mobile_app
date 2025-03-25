import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/my_review_model.dart';
import 'package:tlobni/data/repositories/my_ratings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchMyRatingsState {}

class FetchMyRatingsInitial extends FetchMyRatingsState {}

class FetchMyRatingsInProgress extends FetchMyRatingsState {}

class FetchMyRatingsSuccess extends FetchMyRatingsState {
  final double? averageRating; // Make my nullable
  final List<MyReviewModel> ratings;
  final bool isLoadingMore;
  final bool loadingMoreError;
  final int page;
  final int total;

  FetchMyRatingsSuccess({
    required this.ratings,
    this.averageRating, // Optional, can be null
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.page,
    required this.total,
  });

  FetchMyRatingsSuccess copyWith({
    List<MyReviewModel>? ratings,
    double? averageRating,
    bool? isLoadingMore,
    bool? loadingMoreError,
    int? page,
    int? total,
  }) {
    return FetchMyRatingsSuccess(
      ratings: ratings ?? this.ratings,
      averageRating: averageRating ?? this.averageRating,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchMyRatingsFail extends FetchMyRatingsState {
  final dynamic error;

  FetchMyRatingsFail(this.error);
}

class FetchMyRatingsCubit extends Cubit<FetchMyRatingsState> {
  FetchMyRatingsCubit() : super(FetchMyRatingsInitial());

  final MyRatingsRepository _myRatingsRepository = MyRatingsRepository();

  void fetch() async {
    try {
      emit(FetchMyRatingsInProgress());
      DataOutput<MyReviewModel> result =
          await _myRatingsRepository.fetchMyRatingsAllRatings(page: 1);

      emit(
        FetchMyRatingsSuccess(
          page: 1,
          averageRating: result.extraData?.data,
          isLoadingMore: false,
          loadingMoreError: false,
          ratings: result.modelList,
          total: result.total,
        ),
      );
    } catch (e) {
      emit(FetchMyRatingsFail(e.toString()));
    }
  }

  Future<void> fetchMore() async {
    try {
      if (state is FetchMyRatingsSuccess) {
        if ((state as FetchMyRatingsSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchMyRatingsSuccess).copyWith(isLoadingMore: true));
        DataOutput<MyReviewModel> result =
            await _myRatingsRepository.fetchMyRatingsAllRatings(
          page: (state as FetchMyRatingsSuccess).page + 1,
        );

        FetchMyRatingsSuccess myRatingsModelState =
            (state as FetchMyRatingsSuccess);
        myRatingsModelState.ratings.addAll(result.modelList);
        emit(FetchMyRatingsSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            averageRating: result.extraData?.data,
            // Handle nullable my
            ratings: myRatingsModelState.ratings,
            page: (state as FetchMyRatingsSuccess).page + 1,
            total: result.total));
      }
    } catch (e) {
      emit((state as FetchMyRatingsSuccess)
          .copyWith(isLoadingMore: false, loadingMoreError: true));
    }
  }

  bool hasMoreData() {
    if (state is FetchMyRatingsSuccess) {
      return (state as FetchMyRatingsSuccess).ratings.length <
          (state as FetchMyRatingsSuccess).total;
    }
    return false;
  }

  double? averageRating() {
    if (state is FetchMyRatingsSuccess) {
      return (state as FetchMyRatingsSuccess).averageRating;
    }

    return null;
  }

  void updateIsExpanded(int index) {
    //this will create new chat in chat list if there is no already
    if (state is FetchMyRatingsSuccess) {
      List<MyReviewModel> ratingsList =
          (state as FetchMyRatingsSuccess).ratings;

      ratingsList[index] = ratingsList[index].copyWith(
        isExpanded: !(ratingsList[index].isExpanded ?? false),
      );
      if (!isClosed) {
        emit((state as FetchMyRatingsSuccess).copyWith(ratings: ratingsList));
      }
    }
  }

  void updateReportReason(int itemReportId, String reportReason) {
    if (state is FetchMyRatingsSuccess) {
      final ratings = (state as FetchMyRatingsSuccess).ratings;
      int indexToUpdate =
          ratings.indexWhere((element) => element.id == itemReportId);
      if (indexToUpdate != -1) {
        // Update the myPurchase model at the specific index
        ratings[indexToUpdate].reportStatus = 'reported';
        ratings[indexToUpdate].reportReason = reportReason;

        emit(
          FetchMyRatingsSuccess(
              ratings: List.from(ratings),
              isLoadingMore: (state as FetchMyRatingsSuccess).isLoadingMore,
              loadingMoreError:
                  (state as FetchMyRatingsSuccess).loadingMoreError,
              page: (state as FetchMyRatingsSuccess).page,
              total: (state as FetchMyRatingsSuccess).total,
              averageRating: (state as FetchMyRatingsSuccess).averageRating),
        );
      }
    }
  }
}
