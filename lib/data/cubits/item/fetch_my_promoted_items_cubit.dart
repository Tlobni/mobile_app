import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchMyPromotedItemsState {}

class FetchMyPromotedItemsInitial extends FetchMyPromotedItemsState {}

class FetchMyPromotedItemsInProgress extends FetchMyPromotedItemsState {}

class FetchMyPromotedItemsSuccess extends FetchMyPromotedItemsState {
  final bool isLoadingMore;
  final bool loadingMoreError;
  final List<ItemModel> itemModel;
  final int page;
  final int total;

  FetchMyPromotedItemsSuccess({
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.itemModel,
    required this.page,
    required this.total,
  });

  FetchMyPromotedItemsSuccess copyWith({
    bool? isLoadingMore,
    bool? loadingMoreError,
    List<ItemModel>? itemModel,
    int? page,
    int? total,
  }) {
    return FetchMyPromotedItemsSuccess(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      itemModel: itemModel ?? this.itemModel,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchMyPromotedItemsFailure extends FetchMyPromotedItemsState {
  final dynamic errorMessage;

  FetchMyPromotedItemsFailure(this.errorMessage);
}

class FetchMyPromotedItemsCubit extends Cubit<FetchMyPromotedItemsState> {
  FetchMyPromotedItemsCubit() : super(FetchMyPromotedItemsInitial());

  final ItemRepository _itemRepository = ItemRepository();

  Future<void> fetchMyPromotedItems() async {
    try {
      emit(FetchMyPromotedItemsInProgress());

      DataOutput<ItemModel> result =
          await _itemRepository.fetchMyFeaturedItems(page: 1);

      emit(
        FetchMyPromotedItemsSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          itemModel: result.modelList,
          page: 1,
          total: result.total,
        ),
      );
    } catch (e) {
      emit(FetchMyPromotedItemsFailure(e));
    }
  }

  void delete(dynamic id) {
    if (state is FetchMyPromotedItemsSuccess) {
      List<ItemModel> itemModel =
          (state as FetchMyPromotedItemsSuccess).itemModel;
      itemModel.removeWhere((element) => element.id == id);

      emit((state as FetchMyPromotedItemsSuccess)
          .copyWith(itemModel: itemModel));
    }
  }

  Future<void> fetchMyPromotedItemsMore() async {
    try {
      if (state is FetchMyPromotedItemsSuccess) {
        if ((state as FetchMyPromotedItemsSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchMyPromotedItemsSuccess)
            .copyWith(isLoadingMore: true));
        DataOutput<ItemModel> result =
            await _itemRepository.fetchMyFeaturedItems(
          page: (state as FetchMyPromotedItemsSuccess).page + 1,
        );

        FetchMyPromotedItemsSuccess itemModelState =
            (state as FetchMyPromotedItemsSuccess);
        itemModelState.itemModel.addAll(result.modelList);
        emit(FetchMyPromotedItemsSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            itemModel: itemModelState.itemModel,
            page: (state as FetchMyPromotedItemsSuccess).page + 1,
            total: result.total));
      }
    } catch (e) {
      emit((state as FetchMyPromotedItemsSuccess)
          .copyWith(isLoadingMore: false, loadingMoreError: true));
    }
  }

  bool hasMoreData() {
    if (state is FetchMyPromotedItemsSuccess) {
      return (state as FetchMyPromotedItemsSuccess).itemModel.length <
          (state as FetchMyPromotedItemsSuccess).total;
    }
    return false;
  }

  void update(ItemModel model) {
    if (state is FetchMyPromotedItemsSuccess) {
      List<ItemModel> items = (state as FetchMyPromotedItemsSuccess).itemModel;

      var index = items.indexWhere((element) => element.id == model.id);
      if (index != -1) {
        items[index] = model;
      }

      emit((state as FetchMyPromotedItemsSuccess).copyWith(itemModel: items));
    }
  }
}
