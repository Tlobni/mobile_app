import 'dart:developer';

import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FetchMyItemsState {}

class FetchMyItemsInitial extends FetchMyItemsState {}

class FetchMyItemsInProgress extends FetchMyItemsState {}

class FetchMyItemsSuccess extends FetchMyItemsState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<ItemModel> items;
  final String? getItemsWithStatus;

  FetchMyItemsSuccess(
      {required this.total,
      required this.page,
      required this.isLoadingMore,
      required this.hasError,
      required this.getItemsWithStatus,
      required this.items});

  FetchMyItemsSuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<ItemModel>? items,
    String? getItemsWithStatus,
    bool? getActiveItems,
  }) {
    return FetchMyItemsSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      items: items ?? this.items,
      getItemsWithStatus: getItemsWithStatus ?? this.getItemsWithStatus,
    );
  }

  @override
  String toString() {
    return 'FetchMyItemsSuccess{items: $items, getItemsWithStatus: $getItemsWithStatus}';
  }
}

class FetchMyItemsFailed extends FetchMyItemsState {
  final dynamic error;

  FetchMyItemsFailed(this.error);
}

class FetchMyItemsCubit extends Cubit<FetchMyItemsState> {
  FetchMyItemsCubit() : super(FetchMyItemsInitial());
  final ItemRepository _itemRepository = ItemRepository();

  void fetchMyItems({String? getItemsWithStatus}) async {
    try {
      emit(FetchMyItemsInProgress());
      DataOutput<ItemModel> result = await _itemRepository.fetchMyItems(
        page: 1,
        getItemsWithStatus: getItemsWithStatus,
      );
      emit(FetchMyItemsSuccess(
          hasError: false,
          isLoadingMore: false,
          page: 1,
          items: result.modelList,
          total: result.total,
          getItemsWithStatus: getItemsWithStatus));
    } catch (e) {
      emit(FetchMyItemsFailed(e.toString()));
    }
  }

  void addItem(ItemModel item) {
    if (state is FetchMyItemsSuccess) {
      List<ItemModel> items = (state as FetchMyItemsSuccess).items;
      items.insert(0, item);

      emit((state as FetchMyItemsSuccess).copyWith(items: items));
    }
  }

  void deleteItem(ItemModel model) {
    if (state is FetchMyItemsSuccess) {
      List<ItemModel> items = (state as FetchMyItemsSuccess).items;

      items.removeWhere(((element) => (element.id == model.id)));

      emit((state as FetchMyItemsSuccess).copyWith(items: items));
    }
  }

  void edit(ItemModel item) {
    if (state is FetchMyItemsSuccess) {
      List<ItemModel> items = (state as FetchMyItemsSuccess).items;
      log('$state');
      int index = items.indexWhere((element) {
        log('${element.id} - ${item.id}');
        return element.id == item.id;
      });
      items[index] = item;
      if (!isClosed) {
        emit((state as FetchMyItemsSuccess).copyWith(items: items));
      }
    }
  }

  Future<void> fetchMyMoreItems({String? getItemsWithStatus}) async {
    try {
      if (state is FetchMyItemsSuccess) {
        if ((state as FetchMyItemsSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchMyItemsSuccess).copyWith(isLoadingMore: true));

        DataOutput<ItemModel> result = await _itemRepository.fetchMyItems(
          getItemsWithStatus: getItemsWithStatus,
          page: (state as FetchMyItemsSuccess).page + 1,
        );

        FetchMyItemsSuccess myItemsState = (state as FetchMyItemsSuccess);
        myItemsState.items.addAll(result.modelList);
        emit(
          FetchMyItemsSuccess(
            isLoadingMore: false,
            hasError: false,
            items: myItemsState.items,
            page: (state as FetchMyItemsSuccess).page + 1,
            getItemsWithStatus: getItemsWithStatus,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchMyItemsSuccess).copyWith(
          isLoadingMore: false,
          hasError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchMyItemsSuccess) {
      return (state as FetchMyItemsSuccess).items.length <
          (state as FetchMyItemsSuccess).total;
    }
    return false;
  }
}
