import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/data/repositories/user/user_repository.dart';

enum SearchProviderSortBy {
  rating,
  newest;

  String get jsonName => switch (this) {
        SearchProviderSortBy.rating => 'rating',
        SearchProviderSortBy.newest => 'newest',
      };
}

abstract class SearchProvidersState {}

class SearchProvidersInitial extends SearchProvidersState {}

class SearchProvidersFetchProgress extends SearchProvidersState {}

class SearchProvidersProgress extends SearchProvidersState {}

class SearchProvidersSuccess extends SearchProvidersState {
  final int total;
  final int page;
  final String searchQuery;
  final bool isLoadingMore;
  final bool hasError;
  final bool hasMore;
  final List<UserModel> searchedProviders;

  SearchProvidersSuccess({
    required this.searchQuery,
    required this.total,
    required this.page,
    required this.isLoadingMore,
    required this.hasError,
    required this.searchedProviders,
    required this.hasMore,
  });

  SearchProvidersSuccess copyWith({
    int? total,
    int? page,
    String? searchQuery,
    bool? isLoadingMore,
    bool? hasError,
    bool? hasMore,
    List<UserModel>? searchedProviders,
  }) {
    return SearchProvidersSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      hasMore: hasMore ?? this.hasMore,
      searchedProviders: searchedProviders ?? this.searchedProviders,
    );
  }
}

class SearchProvidersFailure extends SearchProvidersState {
  final String errorMessage;

  SearchProvidersFailure(this.errorMessage);
}

class SearchProvidersCubit extends Cubit<SearchProvidersState> {
  SearchProvidersCubit() : super(SearchProvidersInitial());

  final UserRepository _userRepository = UserRepository();

  Future<void> searchProviders(
    String query, {
    required int page,
    ItemFilterModel? filter,
  }) async {
    try {
      emit(SearchProvidersFetchProgress());
      DataOutput<UserModel> result = await _userRepository.fetchProviders(query, filter, page: page);

      emit(SearchProvidersSuccess(
        searchQuery: query,
        total: result.total,
        hasError: false,
        isLoadingMore: false,
        page: page,
        searchedProviders: result.modelList,
        hasMore: (result.modelList.length < result.total),
      ));
    } catch (e) {
      if (e.toString() == "No Data Found") {
        emit(SearchProvidersSuccess(
          searchQuery: query,
          total: 0,
          hasError: false,
          isLoadingMore: false,
          page: page,
          searchedProviders: [],
          hasMore: false,
        ));
      } else {
        emit(SearchProvidersFailure(e.toString()));
      }
    }
  }

  void clearSearch() {
    if (state is SearchProvidersSuccess) {
      emit(SearchProvidersInitial());
    }
  }

  Future<void> fetchMoreProviders(
    String query,
    ItemFilterModel? filter,
  ) async {
    try {
      if (state is SearchProvidersSuccess) {
        if ((state as SearchProvidersSuccess).isLoadingMore) {
          return;
        }
        emit((state as SearchProvidersSuccess).copyWith(isLoadingMore: true));

        DataOutput<UserModel> result = await _userRepository.fetchProviders(
          query,
          filter,
          page: (state as SearchProvidersSuccess).page + 1,
        );
        List<UserModel> updatedResults = (state as SearchProvidersSuccess).searchedProviders;
        updatedResults.addAll(result.modelList);

        emit(
          SearchProvidersSuccess(
            searchQuery: query,
            isLoadingMore: false,
            hasError: false,
            searchedProviders: updatedResults,
            page: (state as SearchProvidersSuccess).page + 1,
            total: result.total,
            hasMore: updatedResults.length < result.total,
          ),
        );
      }
    } catch (e) {
      emit(SearchProvidersSuccess(
        isLoadingMore: false,
        searchedProviders: (state as SearchProvidersSuccess).searchedProviders,
        hasError: (e.toString() == "No Data Found") ? false : true,
        page: (state as SearchProvidersSuccess).page + 1,
        total: (state as SearchProvidersSuccess).total,
        hasMore: (state as SearchProvidersSuccess).hasMore,
        searchQuery: query,
      ));
    }
  }

  bool hasMoreData() {
    return (state is SearchProvidersSuccess) ? (state as SearchProvidersSuccess).hasMore : false;
  }
}
