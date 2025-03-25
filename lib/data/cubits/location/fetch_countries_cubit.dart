import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/location/countries_model.dart';
import 'package:tlobni/data/repositories/location/countries_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchCountriesState {}

class FetchCountriesInitial extends FetchCountriesState {}

class FetchCountriesInProgress extends FetchCountriesState {}

class FetchCountriesSuccess extends FetchCountriesState {
  final bool isLoadingMore;
  final bool loadingMoreError;
  final List<CountriesModel> countriesModel;
  final int page;
  final int total;

  FetchCountriesSuccess({
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.countriesModel,
    required this.page,
    required this.total,
  });

  FetchCountriesSuccess copyWith({
    bool? isLoadingMore,
    bool? loadingMoreError,
    List<CountriesModel>? countriesModel,
    int? page,
    int? total,
  }) {
    return FetchCountriesSuccess(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      countriesModel: countriesModel ?? this.countriesModel,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchCountriesFailure extends FetchCountriesState {
  final String errorMessage;

  FetchCountriesFailure(this.errorMessage);
}

class FetchCountriesCubit extends Cubit<FetchCountriesState> {
  FetchCountriesCubit() : super(FetchCountriesInitial());

  final CountriesRepository _countriesRepository = CountriesRepository();

  Future<void> fetchCountries({required String search}) async {
    try {
      emit(FetchCountriesInProgress());

      DataOutput<CountriesModel> result =
          await _countriesRepository.fetchCountries(page: 1, search: search);
      emit(
        FetchCountriesSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          countriesModel: result.modelList,
          page: 1,
          total: result.total,
        ),
      );
    } catch (e) {
      emit(
        FetchCountriesFailure(
          e.toString(),
        ),
      );
    }
  }

  Future<void> fetchCountriesMore() async {
    try {
      if (state is FetchCountriesSuccess) {
        if ((state as FetchCountriesSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchCountriesSuccess).copyWith(isLoadingMore: true));

        DataOutput<CountriesModel> result = await _countriesRepository
            .fetchCountries(page: (state as FetchCountriesSuccess).page + 1);

        FetchCountriesSuccess countries = (state as FetchCountriesSuccess);

        countries.countriesModel.addAll(result.modelList);

        emit(
          FetchCountriesSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            countriesModel: countries.countriesModel,
            page: (state as FetchCountriesSuccess).page + 1,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchCountriesSuccess).copyWith(
          isLoadingMore: false,
          loadingMoreError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchCountriesSuccess) {
      return (state as FetchCountriesSuccess).countriesModel.length <
          (state as FetchCountriesSuccess).total;
    }
    return false;
  }
}
