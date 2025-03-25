import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FetchPopularItemsState {}

class FetchPopularItemsInitial extends FetchPopularItemsState {}

class FetchPopularItemsInProgress extends FetchPopularItemsState {}

class FetchPopularItemsSuccess extends FetchPopularItemsState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<ItemModel> items;
  final String? sortBy;

  FetchPopularItemsSuccess(
      {required this.total,
      required this.page,
      required this.isLoadingMore,
      required this.hasError,
      required this.sortBy,
      required this.items});

  FetchPopularItemsSuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<ItemModel>? items,
    String? sortBy,
    bool? getActiveItems,
  }) {
    return FetchPopularItemsSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      items: items ?? this.items,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class FetchPopularItemsFailed extends FetchPopularItemsState {
  final dynamic error;

  FetchPopularItemsFailed(this.error);
}

class FetchPopularItemsCubit extends Cubit<FetchPopularItemsState> {
  FetchPopularItemsCubit() : super(FetchPopularItemsInitial());
  final ItemRepository _itemRepository = ItemRepository();

  void fetchPopularItems() async {
    try {
      emit(FetchPopularItemsInProgress());
      DataOutput<ItemModel> result = await _itemRepository.fetchPopularItems(
        sortBy: "popular_items",
        page: 1,
      );
      emit(FetchPopularItemsSuccess(
          hasError: false,
          isLoadingMore: false,
          page: 1,
          items: result.modelList,
          total: result.total,
          sortBy: "popular_items"));
    } catch (e) {
      emit(FetchPopularItemsFailed(e.toString()));
    }
  }

  Future<void> fetchMyMoreItems() async {
    try {
      if (state is FetchPopularItemsSuccess) {
        if ((state as FetchPopularItemsSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchPopularItemsSuccess).copyWith(isLoadingMore: true));

        DataOutput<ItemModel> result = await _itemRepository.fetchPopularItems(
          sortBy: "popular_items",
          page: (state as FetchPopularItemsSuccess).page + 1,
        );

        FetchPopularItemsSuccess myItemsState =
            (state as FetchPopularItemsSuccess);
        myItemsState.items.addAll(result.modelList);
        emit(
          FetchPopularItemsSuccess(
            isLoadingMore: false,
            hasError: false,
            items: myItemsState.items,
            page: (state as FetchPopularItemsSuccess).page + 1,
            sortBy: "popular_items",
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchPopularItemsSuccess).copyWith(
          isLoadingMore: false,
          hasError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchPopularItemsSuccess) {
      return (state as FetchPopularItemsSuccess).items.length <
          (state as FetchPopularItemsSuccess).total;
    }
    return false;
  }
}
