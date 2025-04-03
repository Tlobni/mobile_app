import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/home/home_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchSectionItemsState {}

class FetchSectionItemsInitial extends FetchSectionItemsState {}

class FetchSectionItemsInProgress extends FetchSectionItemsState {}

class FetchSectionItemsSuccess extends FetchSectionItemsState {
  final List<ItemModel> items;
  final bool isLoadingMore;
  final bool loadingMoreError;
  final int page;
  final int total;

  FetchSectionItemsSuccess(
      {required this.items,
      required this.isLoadingMore,
      required this.loadingMoreError,
      required this.page,
      required this.total});

  FetchSectionItemsSuccess copyWith({
    List<ItemModel>? items,
    bool? isLoadingMore,
    bool? loadingMoreError,
    int? page,
    int? total,
  }) {
    return FetchSectionItemsSuccess(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchSectionItemsFail extends FetchSectionItemsState {
  final dynamic error;

  FetchSectionItemsFail(this.error);
}

class FetchSectionItemsCubit extends Cubit<FetchSectionItemsState> {
  final HomeRepository _homeRepository;
  final List<ItemModel> _items = [];
  bool _hasMore = true;
  int _page = 1;
  bool _isLoadingMore = false;
  Map<String, dynamic>? _filter;

  FetchSectionItemsCubit(this._homeRepository)
      : super(FetchSectionItemsInitial());

  void setFilter(Map<String, dynamic> filter) {
    _filter = filter;
  }

  void fetchSectionItem(
      {required int sectionId,
      String? city,
      int? areaId,
      String? country,
      String? state,
      String? endpoint}) async {
    try {
      emit(FetchSectionItemsInProgress());
      _page = 1;
      _items.clear();
      _hasMore = true;

      DataOutput<ItemModel> result = await _homeRepository.fetchSectionItems(
          page: _page,
          sectionId: sectionId,
          city: city,
          areaId: areaId,
          country: country,
          state: state,
          endpoint: endpoint,
          filter: _filter);

      _items.addAll(result.modelList);
      _hasMore = _items.length < result.total;
      emit(FetchSectionItemsSuccess(
        items: _items,
        page: _page,
        total: result.total,
        isLoadingMore: false,
        loadingMoreError: false,
      ));
    } catch (e) {
      emit(FetchSectionItemsFail(e));
    }
  }

  void fetchSectionItemMore(
      {required int sectionId,
      String? city,
      int? areaId,
      String? country,
      String? stateName,
      String? endpoint}) async {
    if (!_hasMore || _isLoadingMore) return;

    try {
      _isLoadingMore = true;
      _page++;

      DataOutput<ItemModel> result = await _homeRepository.fetchSectionItems(
          page: _page,
          sectionId: sectionId,
          city: city,
          areaId: areaId,
          country: country,
          state: stateName,
          endpoint: endpoint,
          filter: _filter);

      _items.addAll(result.modelList);
      _hasMore = _items.length < result.total;
      emit(FetchSectionItemsSuccess(
        items: _items,
        page: _page,
        total: result.total,
        isLoadingMore: false,
        loadingMoreError: false,
      ));
    } catch (e) {
      emit(FetchSectionItemsFail(e));
    } finally {
      _isLoadingMore = false;
    }
  }

  bool hasMoreData() {
    return _hasMore;
  }

  FetchSectionItemsState? fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
    return null;
  }

  Map<String, dynamic>? toJson(FetchSectionItemsState state) {
    // TODO: implement toJson
    return null;
  }
}
