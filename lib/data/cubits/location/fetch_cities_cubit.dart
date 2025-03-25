import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/location/city_model.dart';
import 'package:tlobni/data/repositories/location/cities_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchCitiesState {}

class FetchCitiesInitial extends FetchCitiesState {}

class FetchCitiesInProgress extends FetchCitiesState {}

class FetchCitiesSuccess extends FetchCitiesState {
  final bool isLoadingMore;
  final bool loadingMoreError;
  final List<CityModel> citiesModel;
  final int page;
  final int total;
  final int? stateId;

  FetchCitiesSuccess(
      {required this.isLoadingMore,
      required this.loadingMoreError,
      required this.citiesModel,
      required this.page,
      required this.total,
      this.stateId});

  FetchCitiesSuccess copyWith(
      {bool? isLoadingMore,
      bool? loadingMoreError,
      List<CityModel>? citiesModel,
      int? page,
      int? total,
      int? stateId}) {
    return FetchCitiesSuccess(
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadingMoreError: loadingMoreError ?? this.loadingMoreError,
        citiesModel: citiesModel ?? this.citiesModel,
        page: page ?? this.page,
        total: total ?? this.total,
        stateId: stateId ?? this.stateId);
  }
}

class FetchCitiesFailure extends FetchCitiesState {
  final String errorMessage;

  FetchCitiesFailure(this.errorMessage);
}

class FetchCitiesCubit extends Cubit<FetchCitiesState> {
  FetchCitiesCubit() : super(FetchCitiesInitial());

  final CitiesRepository _citiesRepository = CitiesRepository();

  Future<void> fetchCities({required int stateId, String? search}) async {
    try {
      emit(FetchCitiesInProgress());

      DataOutput<CityModel> result = await _citiesRepository.fetchCities(
          stateId: stateId, page: 1, search: search);
      emit(
        FetchCitiesSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          citiesModel: result.modelList,
          page: 1,
          total: result.total,
          stateId: stateId,
        ),
      );
    } catch (e) {
      emit(
        FetchCitiesFailure(
          e.toString(),
        ),
      );
    }
  }

  Future<void> fetchCitiesMore({required int stateId}) async {
    try {
      if (state is FetchCitiesSuccess) {
        if ((state as FetchCitiesSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchCitiesSuccess).copyWith(isLoadingMore: true));

        DataOutput<CityModel> result = await _citiesRepository.fetchCities(
            stateId: stateId, page: (state as FetchCitiesSuccess).page + 1);

        FetchCitiesSuccess cities = (state as FetchCitiesSuccess);

        cities.citiesModel.addAll(result.modelList);

        emit(
          FetchCitiesSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            citiesModel: cities.citiesModel,
            page: (state as FetchCitiesSuccess).page + 1,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchCitiesSuccess).copyWith(
          isLoadingMore: false,
          loadingMoreError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchCitiesSuccess) {
      return (state as FetchCitiesSuccess).citiesModel.length <
          (state as FetchCitiesSuccess).total;
    }
    return false;
  }
}
