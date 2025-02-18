import 'package:eClassify/data/model/home/home_screen_section.dart';
import 'package:eClassify/data/repositories/home/home_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchHomeScreenState {}

class FetchHomeScreenInitial extends FetchHomeScreenState {}

class FetchHomeScreenInProgress extends FetchHomeScreenState {}

class FetchHomeScreenSuccess extends FetchHomeScreenState {
  final List<HomeScreenSection> sections;

  FetchHomeScreenSuccess(this.sections);
}

class FetchHomeScreenFail extends FetchHomeScreenState {
  final dynamic error;

  FetchHomeScreenFail(this.error);
}

class FetchHomeScreenCubit extends Cubit<FetchHomeScreenState> {
  FetchHomeScreenCubit() : super(FetchHomeScreenInitial());

  final HomeRepository _homeRepository = HomeRepository();

  void fetch(
      {String? country, String? state, String? city, int? areaId}) async {
    try {
      emit(FetchHomeScreenInProgress());
      List<HomeScreenSection> homeScreenDataList =
          await _homeRepository.fetchHome(
              city: city, areaId: areaId, country: country, state: state);

      emit(FetchHomeScreenSuccess(homeScreenDataList));
    } catch (e) {
      print('Issue while loading home screen $e');
      emit(FetchHomeScreenFail(e));
    }
  }

  FetchHomeScreenState? fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
    return null;
  }

  Map<String, dynamic>? toJson(FetchHomeScreenState state) {
    // TODO: implement toJson
    return null;
  }
}
