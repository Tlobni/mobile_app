import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/model/item_filter_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchItemFromCategoryState {}

class FetchItemFromCategoryInitial extends FetchItemFromCategoryState {}

class FetchItemFromCategoryInProgress extends FetchItemFromCategoryState {}

class FetchItemFromCategorySuccess extends FetchItemFromCategoryState {
  final bool isLoadingMore;
  final bool loadingMoreError;
  final List<ItemModel> itemModel;
  final int page;
  final int total;
  final int? categoryId;

  FetchItemFromCategorySuccess(
      {required this.isLoadingMore,
      required this.loadingMoreError,
      required this.itemModel,
      required this.page,
      required this.total,
      this.categoryId});

  FetchItemFromCategorySuccess copyWith(
      {bool? isLoadingMore,
      bool? loadingMoreError,
      List<ItemModel>? itemModel,
      int? page,
      int? total,
      int? categoryId}) {
    return FetchItemFromCategorySuccess(
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadingMoreError: loadingMoreError ?? this.loadingMoreError,
        itemModel: itemModel ?? this.itemModel,
        page: page ?? this.page,
        total: total ?? this.total,
        categoryId: categoryId ?? this.categoryId);
  }
}

class FetchItemFromCategoryFailure extends FetchItemFromCategoryState {
  final String errorMessage;

  FetchItemFromCategoryFailure(this.errorMessage);
}

class FetchItemFromCategoryCubit extends Cubit<FetchItemFromCategoryState> {
  FetchItemFromCategoryCubit() : super(FetchItemFromCategoryInitial());

  final ItemRepository _itemRepository = ItemRepository();

  Future<void> fetchItemFromCategory(
      {required int categoryId,
      required String search,
      String? sortBy,
      ItemFilterModel? filter}) async {
    try {
      emit(FetchItemFromCategoryInProgress());

      DataOutput<ItemModel> result = await _itemRepository.fetchItemFromCatId(
          categoryId: categoryId,
          page: 1,
          search: search,
          sortBy: sortBy,
          filter: filter);
      emit(
        FetchItemFromCategorySuccess(
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
        FetchItemFromCategoryFailure(
          e.toString(),
        ),
      );
    }
  }

  Future<void> fetchItemFromCategoryMore(
      {required int catId,
      required String? search,
      String? sortBy,
      ItemFilterModel? filter}) async {
    try {
      if (state is FetchItemFromCategorySuccess) {
        if ((state as FetchItemFromCategorySuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchItemFromCategorySuccess)
            .copyWith(isLoadingMore: true));

        DataOutput<ItemModel> result = await _itemRepository.fetchItemFromCatId(
            categoryId: catId,
            page: (state as FetchItemFromCategorySuccess).page + 1,
            search: search,
            sortBy: sortBy,
            filter: filter);

        FetchItemFromCategorySuccess item =
            (state as FetchItemFromCategorySuccess);

        item.itemModel.addAll(result.modelList);

        emit(
          FetchItemFromCategorySuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            itemModel: item.itemModel,
            page: (state as FetchItemFromCategorySuccess).page + 1,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchItemFromCategorySuccess).copyWith(
          isLoadingMore: false,
          loadingMoreError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchItemFromCategorySuccess) {
      return (state as FetchItemFromCategorySuccess).itemModel.length <
          (state as FetchItemFromCategorySuccess).total;
    }
    return false;
  }
}
