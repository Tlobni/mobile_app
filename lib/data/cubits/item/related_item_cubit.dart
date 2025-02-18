import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchRelatedItemsState {}

class FetchRelatedItemsInitial extends FetchRelatedItemsState {}

class FetchRelatedItemsInProgress extends FetchRelatedItemsState {}

class FetchRelatedItemsSuccess extends FetchRelatedItemsState {
  final bool isLoadingMore;
  final bool loadingMoreError;
  final List<ItemModel> itemModel;
  final int page;
  final int total;
  final int? categoryId;

  FetchRelatedItemsSuccess(
      {required this.isLoadingMore,
      required this.loadingMoreError,
      required this.itemModel,
      required this.page,
      required this.total,
      this.categoryId});

  FetchRelatedItemsSuccess copyWith(
      {bool? isLoadingMore,
      bool? loadingMoreError,
      List<ItemModel>? itemModel,
      int? page,
      int? total,
      int? categoryId}) {
    return FetchRelatedItemsSuccess(
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadingMoreError: loadingMoreError ?? this.loadingMoreError,
        itemModel: itemModel ?? this.itemModel,
        page: page ?? this.page,
        total: total ?? this.total,
        categoryId: categoryId ?? this.categoryId);
  }
}

class FetchRelatedItemsFailure extends FetchRelatedItemsState {
  final String errorMessage;

  FetchRelatedItemsFailure(this.errorMessage);
}

class FetchRelatedItemsCubit extends Cubit<FetchRelatedItemsState> {
  FetchRelatedItemsCubit() : super(FetchRelatedItemsInitial());

  final ItemRepository _itemRepository = ItemRepository();

  Future<void> fetchRelatedItems(
      {required int categoryId,
      String? country,
      String? state,
      String? city,
      int? areaId}) async {
    try {
      emit(FetchRelatedItemsInProgress());

      DataOutput<ItemModel> result = await _itemRepository.fetchItemFromCatId(
          categoryId: categoryId,
          page: 1,
          areaId: areaId,
          city: city,
          country: country,
          state: state);

      emit(
        FetchRelatedItemsSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          itemModel: result.modelList,
          page: 1,
          total: result.total,
          categoryId: categoryId,
        ),
      );
    } catch (e) {
      emit(
        FetchRelatedItemsFailure(
          e.toString(),
        ),
      );
    }
  }

  Future<void> fetchRelatedItemsMore(
      {required int categoryId,
      String? country,
      String? state,
      String? city,
      int? areaId}) async {
    try {
      if (state is FetchRelatedItemsSuccess) {
        if ((state as FetchRelatedItemsSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchRelatedItemsSuccess).copyWith(isLoadingMore: true));

        DataOutput<ItemModel> result = await _itemRepository.fetchItemFromCatId(
            categoryId: categoryId,
            areaId: areaId,
            city: city,
            country: country,
            state: state,
            page: (state as FetchRelatedItemsSuccess).page + 1);

        FetchRelatedItemsSuccess item = (state as FetchRelatedItemsSuccess);

        item.itemModel.addAll(result.modelList);

        emit(
          FetchRelatedItemsSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            itemModel: item.itemModel,
            page: (state as FetchRelatedItemsSuccess).page + 1,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchRelatedItemsSuccess).copyWith(
          isLoadingMore: false,
          loadingMoreError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchRelatedItemsSuccess) {
      return (state as FetchRelatedItemsSuccess).itemModel.length <
          (state as FetchRelatedItemsSuccess).total;
    }
    return false;
  }
}
