// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:tlobni/data/helper/custom_exception.dart';
import 'package:tlobni/data/model/home_slider.dart';
import 'package:tlobni/settings.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/network/network_availability.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SliderState {}

class SliderInitial extends SliderState {}

class SliderFetchInProgress extends SliderState {}

class SliderFetchInInternalProgress extends SliderState {}

class SliderFetchSuccess extends SliderState {
  List<HomeSlider> sliderlist = [];

  SliderFetchSuccess(this.sliderlist);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sliderlist': sliderlist.map((x) => x.toJson()).toList(),
    };
  }

  factory SliderFetchSuccess.fromMap(Map<String, dynamic> map) {
    return SliderFetchSuccess(
      List<HomeSlider>.from(
        (map['sliderlist']).map<HomeSlider>(
          (x) => HomeSlider.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory SliderFetchSuccess.fromJson(String source) =>
      SliderFetchSuccess.fromMap(json.decode(source) as Map<String, dynamic>);
}

class SliderFetchFailure extends SliderState {
  final String errorMessage;
  final bool isUserDeactivated;
  SliderFetchFailure(
      this.errorMessage, this.isUserDeactivated); //, this.isUserDeactivated
}

class SliderCubit extends Cubit<SliderState> {
  SliderCubit() : super(SliderInitial());

  void fetchSlider(BuildContext context,
      {bool? forceRefresh, bool? loadWithoutDelay}) async {
    if (forceRefresh != true) {
      if (state is SliderFetchSuccess) {
        await Future.delayed(Duration(
            seconds: loadWithoutDelay == true
                ? 0
                : AppSettings.hiddenAPIProcessDelay));
      } else {
        emit(SliderFetchInProgress());
      }
    } else {
      emit(SliderFetchInProgress());
    }

    if (forceRefresh == true) {
      fetchSliderFromDb(context, sendCityName: true)
          .then((value) => emit(SliderFetchSuccess(value)))
          .catchError((e) {
        if (isClosed) return;
        bool isUserActive = true;
        if (e.toString() ==
            "your account has been deactivate! please contact admin") {
          //message from API
          isUserActive = false;
        } else {
          isUserActive = true;
        }
        emit(SliderFetchFailure(e.toString(), isUserActive)); //, isUserActive
      });
    } else {
      if (state is! SliderFetchSuccess) {
        fetchSliderFromDb(context, sendCityName: true)
            .then((value) => emit(SliderFetchSuccess(value)))
            .catchError((e) {
          if (isClosed) return;
          bool isUserActive = true;
          if (e.toString() ==
              "your account has been deactivate! please contact admin") {
            //message from API
            isUserActive = false;
          } else {
            isUserActive = true;
          }
          emit(SliderFetchFailure(e.toString(), isUserActive)); //, isUserActive
        });
      } else {
        await CheckInternet.check(
          onInternet: () async {
            fetchSliderFromDb(context, sendCityName: true)
                .then((value) => emit(SliderFetchSuccess(value)))
                .catchError((e) {
              if (isClosed) return;
              bool isUserActive = true;
              if (e.toString() ==
                  "your account has been deactivate! please contact admin") {
                //message from API
                isUserActive = false;
              } else {
                isUserActive = true;
              }
              emit(SliderFetchFailure(
                  e.toString(), isUserActive)); //, isUserActive
            });
          },
          onNoInternet: () {
            emit(SliderFetchSuccess((state as SliderFetchSuccess).sliderlist));
          },
        );
      }
    }

    Future.delayed(
      Duration.zero,
      () {},
    );
  }

  Future<List<HomeSlider>> fetchSliderFromDb(BuildContext context,
      {required bool sendCityName}) async {
    List<HomeSlider> sliderlist = [];
    Map<String, String> body = {};

    var response = await Api.get(url: Api.getSliderApi, queryParameters: body);

    if (!response[Api.error]) {
      List list = response['data'];
      sliderlist = list.map((model) => HomeSlider.fromJson(model)).toList();
    } else {
      throw CustomException(response[Api.message]);
    }

    return sliderlist;
  }

  SliderState? fromJson(Map<String, dynamic> json) {
    try {
      var state = json['cubit_state'];

      if (state == "SliderFetchSuccess") {
        return SliderFetchSuccess.fromMap(json);
      }
    } catch (e) {}

    return null;
  }

  Map<String, dynamic>? toJson(SliderState state) {
    if (state is SliderFetchSuccess) {
      Map<String, dynamic> map = state.toMap();
      map['cubit_state'] = "SliderFetchSuccess";
      return map;
    }
    return null;
  }
}
