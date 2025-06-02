import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/seller/seller_items_repository.dart';

abstract class FetchSellerItemsState {}

class FetchSellerItemsInitial extends FetchSellerItemsState {}

class FetchSellerItemsInProgress extends FetchSellerItemsState {}

class FetchSellerItemsSuccess extends FetchSellerItemsState {
  final List<ItemModel> items;
  final bool isLoadingMore;
  final bool loadingMoreError;
  final int page;
  final int total;
  final int lastPage;

  FetchSellerItemsSuccess({
    required this.items,
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.page,
    required this.total,
    required this.lastPage,
  });

  FetchSellerItemsSuccess copyWith({
    List<ItemModel>? items,
    bool? isLoadingMore,
    bool? loadingMoreError,
    int? page,
    int? total,
    int? lastPage,
  }) {
    return FetchSellerItemsSuccess(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      page: page ?? this.page,
      total: total ?? this.total,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

class FetchSellerItemsFail extends FetchSellerItemsState {
  final dynamic error;

  FetchSellerItemsFail(this.error);
}

class FetchSellerItemsCubit extends Cubit<FetchSellerItemsState> {
  FetchSellerItemsCubit() : super(FetchSellerItemsInitial());

  final SellerItemsRepository _sellerItemsRepository = SellerItemsRepository();

  void fetch({required int sellerId, int page = 1}) async {
    try {
      emit(FetchSellerItemsInProgress());
      DataOutput<ItemModel> result = await _sellerItemsRepository.fetchSellerItemsAllItems(page: page, sellerId: sellerId);

      emit(
        FetchSellerItemsSuccess(
          page: page,
          isLoadingMore: false,
          loadingMoreError: false,
          items: result.modelList,
          total: result.total,
          lastPage: result.lastPage ?? page,
        ),
      );
    } catch (e) {
      emit(FetchSellerItemsFail(e.toString()));
    }
  }

  Future<void> fetchMore({required int sellerId}) async {
    try {
      if (state is FetchSellerItemsSuccess) {
        print("state as FetchSellerItemsSuccess).isLoadingMore****${(state as FetchSellerItemsSuccess).isLoadingMore}");
        if ((state as FetchSellerItemsSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchSellerItemsSuccess).copyWith(isLoadingMore: true));
        DataOutput<ItemModel> result =
            await _sellerItemsRepository.fetchSellerItemsAllItems(page: (state as FetchSellerItemsSuccess).page + 1, sellerId: sellerId);

        FetchSellerItemsSuccess itemModelState = (state as FetchSellerItemsSuccess);
        itemModelState.items.addAll(result.modelList);
        emit(
          FetchSellerItemsSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            items: itemModelState.items,
            page: (state as FetchSellerItemsSuccess).page + 1,
            total: result.total,
            lastPage: result.lastPage ?? 0,
          ),
        );
      }
    } catch (e) {
      emit((state as FetchSellerItemsSuccess).copyWith(isLoadingMore: false, loadingMoreError: true));
    }
  }

  bool hasMoreData() {
    if (state is FetchSellerItemsSuccess) {
      return (state as FetchSellerItemsSuccess).items.length < (state as FetchSellerItemsSuccess).total;
    }
    return false;
  }
}
