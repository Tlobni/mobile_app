import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/location/area_model.dart';
import 'package:tlobni/data/repositories/location/areas_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchAreasState {}

class FetchAreasInitial extends FetchAreasState {}

class FetchAreasInProgress extends FetchAreasState {}

class FetchAreasSuccess extends FetchAreasState {
  final bool isLoadingMore;
  final bool loadingMoreError;
  final List<AreaModel> areasModel;
  final int page;
  final int total;
  final int? cityId;

  FetchAreasSuccess(
      {required this.isLoadingMore,
      required this.loadingMoreError,
      required this.areasModel,
      required this.page,
      required this.total,
      this.cityId});

  FetchAreasSuccess copyWith(
      {bool? isLoadingMore,
      bool? loadingMoreError,
      List<AreaModel>? areasModel,
      int? page,
      int? total,
      int? cityId}) {
    return FetchAreasSuccess(
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadingMoreError: loadingMoreError ?? this.loadingMoreError,
        areasModel: areasModel ?? this.areasModel,
        page: page ?? this.page,
        total: total ?? this.total,
        cityId: cityId ?? this.cityId);
  }
}

class FetchAreasFailure extends FetchAreasState {
  final String errorMessage;

  FetchAreasFailure(this.errorMessage);
}

class FetchAreasCubit extends Cubit<FetchAreasState> {
  FetchAreasCubit() : super(FetchAreasInitial());

  final AreasRepository _areasRepository = AreasRepository();

  Future<void> fetchAreas({required int cityId, String? search}) async {
    try {
      emit(FetchAreasInProgress());

      DataOutput<AreaModel> result = await _areasRepository.fetchAreas(
          cityId: cityId, page: 1, search: search);
      emit(
        FetchAreasSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          areasModel: result.modelList,
          page: 1,
          total: result.total,
          cityId: cityId,
        ),
      );
    } catch (e) {
      emit(
        FetchAreasFailure(
          e.toString(),
        ),
      );
    }
  }

  Future<void> fetchAreasMore({required int cityId}) async {
    try {
      if (state is FetchAreasSuccess) {
        if ((state as FetchAreasSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchAreasSuccess).copyWith(isLoadingMore: true));

        DataOutput<AreaModel> result = await _areasRepository.fetchAreas(
            cityId: cityId, page: (state as FetchAreasSuccess).page + 1);

        FetchAreasSuccess areas = (state as FetchAreasSuccess);

        areas.areasModel.addAll(result.modelList);

        emit(
          FetchAreasSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            areasModel: areas.areasModel,
            page: (state as FetchAreasSuccess).page + 1,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchAreasSuccess).copyWith(
          isLoadingMore: false,
          loadingMoreError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchAreasSuccess) {
      return (state as FetchAreasSuccess).areasModel.length <
          (state as FetchAreasSuccess).total;
    }
    return false;
  }
}
