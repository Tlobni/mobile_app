import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/location/states_model.dart';
import 'package:tlobni/data/repositories/location/states_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchStatesState {}

class FetchStatesInitial extends FetchStatesState {}

class FetchStatesInProgress extends FetchStatesState {}

class FetchStatesSuccess extends FetchStatesState {
  final bool isLoadingMore;
  final bool loadingMoreError;
  final List<StatesModel> statesModel;
  final int page;
  final int total;
  final int? countryId;

  FetchStatesSuccess(
      {required this.isLoadingMore,
      required this.loadingMoreError,
      required this.statesModel,
      required this.page,
      required this.total,
      this.countryId});

  FetchStatesSuccess copyWith(
      {bool? isLoadingMore,
      bool? loadingMoreError,
      List<StatesModel>? statesModel,
      int? page,
      int? total,
      int? countryId}) {
    return FetchStatesSuccess(
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadingMoreError: loadingMoreError ?? this.loadingMoreError,
        statesModel: statesModel ?? this.statesModel,
        page: page ?? this.page,
        total: total ?? this.total,
        countryId: countryId ?? this.countryId);
  }
}

class FetchStatesFailure extends FetchStatesState {
  final String errorMessage;

  FetchStatesFailure(this.errorMessage);
}

class FetchStatesCubit extends Cubit<FetchStatesState> {
  FetchStatesCubit() : super(FetchStatesInitial());

  final StatesRepository _statesRepository = StatesRepository();

  Future<void> fetchStates({
    required String search,
    required int countryId,
  }) async {
    try {
      emit(FetchStatesInProgress());

      DataOutput<StatesModel> result = await _statesRepository.fetchStates(
          countryId: countryId, page: 1, search: search);
      emit(
        FetchStatesSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          statesModel: result.modelList,
          page: 1,
          total: result.total,
          countryId: countryId,
        ),
      );
    } catch (e) {
      emit(
        FetchStatesFailure(
          e.toString(),
        ),
      );
    }
  }

  Future<void> fetchStatesMore({required int countryId}) async {
    try {
      if (state is FetchStatesSuccess) {
        if ((state as FetchStatesSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchStatesSuccess).copyWith(isLoadingMore: true));

        DataOutput<StatesModel> result = await _statesRepository.fetchStates(
            countryId: countryId, page: (state as FetchStatesSuccess).page + 1);

        FetchStatesSuccess states = (state as FetchStatesSuccess);

        states.statesModel.addAll(result.modelList);

        emit(
          FetchStatesSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            statesModel: states.statesModel,
            page: (state as FetchStatesSuccess).page + 1,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchStatesSuccess).copyWith(
          isLoadingMore: false,
          loadingMoreError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchStatesSuccess) {
      return (state as FetchStatesSuccess).statesModel.length <
          (state as FetchStatesSuccess).total;
    }
    return false;
  }
}
