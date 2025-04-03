import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/home/home_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchHomeAllItemsState {}

class FetchHomeAllItemsInitial extends FetchHomeAllItemsState {}

class FetchHomeAllItemsInProgress extends FetchHomeAllItemsState {}

class FetchHomeAllItemsSuccess extends FetchHomeAllItemsState {
  final List<ItemModel> items;
  final bool isLoadingMore;
  final bool loadingMoreError;
  final int page;
  final int total;

  FetchHomeAllItemsSuccess(
      {required this.items,
      required this.isLoadingMore,
      required this.loadingMoreError,
      required this.page,
      required this.total});

  FetchHomeAllItemsSuccess copyWith({
    List<ItemModel>? items,
    bool? isLoadingMore,
    bool? loadingMoreError,
    int? page,
    int? total,
  }) {
    return FetchHomeAllItemsSuccess(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchHomeAllItemsFail extends FetchHomeAllItemsState {
  final dynamic error;

  FetchHomeAllItemsFail(this.error);
}

class FetchHomeAllItemsCubit extends Cubit<FetchHomeAllItemsState> {
  FetchHomeAllItemsCubit() : super(FetchHomeAllItemsInitial());

  final HomeRepository _homeRepository = HomeRepository();

  void fetch(
      {String? country,
      String? state,
      String? city,
      int? areaId,
      int? radius,
      double? latitude,
      double? longitude,
      String? postType,
      bool? isFeatured}) async {
    try {
      emit(FetchHomeAllItemsInProgress());
      DataOutput<ItemModel> result = await _homeRepository.fetchHomeAllItems(
          page: 1,
          city: city,
          areaId: areaId,
          country: country,
          state: state,
          radius: radius,
          longitude: longitude,
          latitude: latitude,
          postType: postType,
          isFeatured: isFeatured);

      emit(
        FetchHomeAllItemsSuccess(
          page: 1,
          isLoadingMore: false,
          loadingMoreError: false,
          items: result.modelList,
          total: result.total,
        ),
      );
    } catch (e) {
      emit(FetchHomeAllItemsFail(e.toString()));
    }
  }

  void updateItem(ItemModel editedItem) {
    if (state is FetchHomeAllItemsSuccess) {
      final currentState = state as FetchHomeAllItemsSuccess;
      final List<ItemModel> updatedItems = List.from(currentState.items);

      final int index =
          updatedItems.indexWhere((item) => item.id == editedItem.id);

      if (index != -1) {
        updatedItems[index] = editedItem;

        emit(currentState.copyWith(items: updatedItems));
      }
    }
  }

  Future<void> fetchMore(
      {String? country,
      String? stateName,
      String? city,
      int? areaId,
      int? radius,
      double? latitude,
      double? longitude,
      String? postType,
      bool? isFeatured}) async {
    if (state is FetchHomeAllItemsSuccess) {
      FetchHomeAllItemsSuccess currentState = state as FetchHomeAllItemsSuccess;
      try {
        if (currentState.isLoadingMore) return;

        emit(currentState.copyWith(isLoadingMore: true));

        DataOutput<ItemModel> result = await _homeRepository.fetchHomeAllItems(
            page: currentState.page + 1,
            city: city,
            areaId: areaId,
            radius: radius,
            longitude: longitude,
            latitude: latitude,
            country: country,
            state: stateName,
            postType: postType,
            isFeatured: isFeatured);

        FetchHomeAllItemsSuccess newUpdate = currentState.copyWith(
          page: currentState.page + 1,
          isLoadingMore: false,
          loadingMoreError: false,
          items: [...currentState.items, ...result.modelList],
          total: result.total,
        );

        emit(newUpdate);
      } catch (e) {
        emit(currentState.copyWith(
            isLoadingMore: false, loadingMoreError: true));
      }
    }
  }

  bool hasMoreData() {
    if (state is FetchHomeAllItemsSuccess) {
      return (state as FetchHomeAllItemsSuccess).items.length <
          (state as FetchHomeAllItemsSuccess).total;
    }
    return false;
  }
}
