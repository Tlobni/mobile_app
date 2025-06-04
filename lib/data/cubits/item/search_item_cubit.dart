// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/data/repositories/item/item_repository.dart';

enum SearchItemSortBy {
  newest,
  priceLowToHigh,
  priceHighToLow,
  topRated;

  String get jsonName => switch (this) {
        SearchItemSortBy.newest => 'new-to-old',
        SearchItemSortBy.priceLowToHigh => 'price-low-to-high',
        SearchItemSortBy.priceHighToLow => 'price-high-to-low',
        SearchItemSortBy.topRated => 'top_rated',
      };
}

abstract class SearchItemState {}

class SearchItemInitial extends SearchItemState {}

class SearchItemFetchProgress extends SearchItemState {}

class SearchItemProgress extends SearchItemState {}

class SearchItemSuccess extends SearchItemState {
  final int total;
  final int page;
  final String searchQuery;
  final bool isLoadingMore;
  final bool hasError;
  final bool hasMore;
  final List<ItemModel> searchedItems;

  SearchItemSuccess({
    required this.searchQuery,
    required this.total,
    required this.page,
    required this.isLoadingMore,
    required this.hasError,
    required this.searchedItems,
    required this.hasMore,
  });

  SearchItemSuccess copyWith({
    int? total,
    int? page,
    String? searchQuery,
    bool? isLoadingMore,
    bool? hasError,
    bool? hasMore,
    List<ItemModel>? searchedItems,
  }) {
    return SearchItemSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      hasMore: hasMore ?? this.hasMore,
      searchedItems: searchedItems ?? this.searchedItems,
    );
  }
}

class SearchItemFailure extends SearchItemState {
  final String errorMessage;

  SearchItemFailure(this.errorMessage);
}

class SearchItemCubit extends Cubit<SearchItemState> {
  SearchItemCubit() : super(SearchItemInitial());

  final ItemRepository _itemRepository = ItemRepository();

  Future<void> searchItem(
    String query, {
    required int page,
    ItemFilterModel? filter,
  }) async {
    try {
      emit(SearchItemFetchProgress());
      DataOutput<ItemModel> result = await _itemRepository.searchItem(query, filter, page: page);

      emit(SearchItemSuccess(
          searchQuery: query,
          total: result.total,
          hasError: false,
          isLoadingMore: false,
          page: page,
          searchedItems: result.modelList,
          hasMore: (result.modelList.length < result.total)));
    } catch (e) {
      if (e.toString() == "No Data Found") {
        //incase of 0 Favorite length - make it success for fresh users

        emit(SearchItemSuccess(
            searchQuery: query, total: 0, hasError: false, isLoadingMore: false, page: page, searchedItems: [], hasMore: false));
      } else {
        emit(SearchItemFailure(e.toString()));
      }
    }
  }

  void clearSearch() {
    if (state is SearchItemSuccess) {
      emit(SearchItemInitial());
    }
  }

  Future<void> fetchMoreSearchData(
    String query,
    ItemFilterModel? filter,
  ) async {
    try {
      if (state is SearchItemSuccess) {
        if ((state as SearchItemSuccess).isLoadingMore) {
          return;
        }
        emit((state as SearchItemSuccess).copyWith(isLoadingMore: true));

        DataOutput<ItemModel> result = await _itemRepository.searchItem(
          query,
          filter,
          page: (state as SearchItemSuccess).page + 1,
        );
        List<ItemModel> updatedResults = (state as SearchItemSuccess).searchedItems;
        updatedResults.addAll(result.modelList);

        emit(
          SearchItemSuccess(
              searchQuery: query,
              isLoadingMore: false,
              hasError: false,
              searchedItems: updatedResults,
              page: (state as SearchItemSuccess).page + 1,
              total: result.total,
              hasMore: updatedResults.length < result.total),
        );
      }
    } catch (e) {
      emit(SearchItemSuccess(
          isLoadingMore: false,
          searchedItems: (state as SearchItemSuccess).searchedItems,
          hasError: (e.toString() == "No Data Found") ? false : true,
          page: (state as SearchItemSuccess).page + 1,
          total: (state as SearchItemSuccess).total,
          hasMore: (state as SearchItemSuccess).hasMore,
          searchQuery: query));
    }
  }

  bool hasMoreData() {
    return (state is SearchItemSuccess) ? (state as SearchItemSuccess).hasMore : false;
  }
}
