import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/seller_ratings_model.dart';
import 'package:eClassify/data/repositories/seller/seller_ratings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchSellerRatingsState {}

class FetchSellerRatingsInitial extends FetchSellerRatingsState {}

class FetchSellerRatingsInProgress extends FetchSellerRatingsState {}

class FetchSellerRatingsSuccess extends FetchSellerRatingsState {
  final Seller? seller; // Make seller nullable
  final List<UserRatings> ratings;
  final bool isLoadingMore;
  final bool loadingMoreError;
  final int page;
  final int total;

  FetchSellerRatingsSuccess({
    required this.ratings,
    this.seller, // Optional, can be null
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.page,
    required this.total,
  });

  FetchSellerRatingsSuccess copyWith({
    List<UserRatings>? ratings,
    Seller? seller,
    bool? isLoadingMore,
    bool? loadingMoreError,
    int? page,
    int? total,
  }) {
    return FetchSellerRatingsSuccess(
      ratings: ratings ?? this.ratings,
      seller: seller ?? this.seller,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchSellerRatingsFail extends FetchSellerRatingsState {
  final dynamic error;

  FetchSellerRatingsFail(this.error);
}

class FetchSellerRatingsCubit extends Cubit<FetchSellerRatingsState> {
  FetchSellerRatingsCubit() : super(FetchSellerRatingsInitial());

  final SellerRatingsRepository _sellerRatingsRepository =
      SellerRatingsRepository();

  void fetch({required int sellerId}) async {
    try {
      print(
          "FetchSellerRatingsCubit: Fetching ratings for seller ID: $sellerId");
      emit(FetchSellerRatingsInProgress());

      DataOutput<UserRatings> result = await _sellerRatingsRepository
          .fetchSellerRatingsAllRatings(page: 1, sellerId: sellerId);

      print(
          "FetchSellerRatingsCubit: Success - Found ${result.modelList.length} ratings with total: ${result.total}");
      print(
          "FetchSellerRatingsCubit: Seller data present: ${result.extraData?.data != null}");

      emit(
        FetchSellerRatingsSuccess(
          page: 1,
          seller: result.extraData?.data,
          isLoadingMore: false,
          loadingMoreError: false,
          ratings: result.modelList,
          total: result.total,
        ),
      );
    } catch (e) {
      print("FetchSellerRatingsCubit: Error fetching ratings - $e");
      emit(FetchSellerRatingsFail(e.toString()));
    }
  }

  Future<void> fetchMore({required int sellerId}) async {
    try {
      if (state is FetchSellerRatingsSuccess) {
        if ((state as FetchSellerRatingsSuccess).isLoadingMore) {
          return;
        }
        emit(
            (state as FetchSellerRatingsSuccess).copyWith(isLoadingMore: true));
        DataOutput<UserRatings> result =
            await _sellerRatingsRepository.fetchSellerRatingsAllRatings(
                page: (state as FetchSellerRatingsSuccess).page + 1,
                sellerId: sellerId);

        FetchSellerRatingsSuccess sellerRatingsModelState =
            (state as FetchSellerRatingsSuccess);
        sellerRatingsModelState.ratings.addAll(result.modelList);
        emit(FetchSellerRatingsSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            seller: result.extraData?.data,
            // Handle nullable seller
            ratings: sellerRatingsModelState.ratings,
            page: (state as FetchSellerRatingsSuccess).page + 1,
            total: result.total));
      }
    } catch (e) {
      emit((state as FetchSellerRatingsSuccess)
          .copyWith(isLoadingMore: false, loadingMoreError: true));
    }
  }

/*  void updateExpanded(int index) {
    if (state is FetchSellerRatingsSuccess) {
      FetchSellerRatingsSuccess currentState =
          state as FetchSellerRatingsSuccess;
      List<UserRatings> updatedRatings = List.from(currentState.ratings);

      // Toggle isExpanded
      updatedRatings[index] = updatedRatings[index].copyWith(
        isExpanded: !(updatedRatings[index].isExpanded ?? false),
      );

      emit(currentState.copyWith(ratings: updatedRatings));
    }
  }*/

  /* void toggleExpandedState(int index) {
    if (state is FetchSellerRatingsSuccess) {
      FetchSellerRatingsSuccess currentState =
          state as FetchSellerRatingsSuccess;

      // Clone the list of ratings
      List<UserRatings> updatedRatings = List.from(currentState.ratings);

      // Reset all other indices to false
      for (int i = 0; i < updatedRatings.length; i++) {
        if (i != index) {
          updatedRatings[i] = updatedRatings[i].copyWith(isExpanded: false);
        }
      }

      // Toggle isExpanded for the selected index
      updatedRatings[index] = updatedRatings[index].copyWith(
        isExpanded: !(updatedRatings[index].isExpanded ?? false),
      );

      // Emit the updated state
      emit(currentState.copyWith(ratings: updatedRatings));
    }
  }*/

  void updateIsExpanded(int index) {
    //this will create new chat in chat list if there is no already
    if (state is FetchSellerRatingsSuccess) {
      List<UserRatings> ratingsList =
          (state as FetchSellerRatingsSuccess).ratings;

      ratingsList[index] = ratingsList[index].copyWith(
        isExpanded: !(ratingsList[index].isExpanded ?? false),
      );
      if (!isClosed) {
        emit((state as FetchSellerRatingsSuccess)
            .copyWith(ratings: ratingsList));
      }
    }
  }

  bool hasMoreData() {
    if (state is FetchSellerRatingsSuccess) {
      return (state as FetchSellerRatingsSuccess).ratings.length <
          (state as FetchSellerRatingsSuccess).total;
    }
    return false;
  }

  Seller? sellerData() {
    if (state is FetchSellerRatingsSuccess) {
      return (state as FetchSellerRatingsSuccess).seller;
    }

    return null;
  }

  int? totalSellerRatings() {
    if (state is FetchSellerRatingsSuccess) {
      return (state as FetchSellerRatingsSuccess).ratings.length;
    }

    return null;
  }
}
