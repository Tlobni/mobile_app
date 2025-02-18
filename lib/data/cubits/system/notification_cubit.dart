import 'package:eClassify/data/helper/custom_exception.dart';
import 'package:eClassify/data/model/notification_data.dart';
import 'package:eClassify/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationSetProgress extends NotificationState {}

class NotificationSetSuccess extends NotificationState {
  List<NotificationData> notificationlist = [];

  NotificationSetSuccess(this.notificationlist);
}

class NotificationSetFailure extends NotificationState {
  final String errmsg;

  NotificationSetFailure(this.errmsg);
}

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationInitial());

  void getNotification(
    BuildContext context,
  ) {
    emit(NotificationSetProgress());
    getNotificationFromDb(
      context,
    )
        .then((value) => emit(NotificationSetSuccess(value)))
        .catchError((e) => emit(NotificationSetFailure(e.toString())));
  }

  Future<List<NotificationData>> getNotificationFromDb(
    BuildContext context,
  ) async {
    Map<String, String> body = {};
    List<NotificationData> notificationList = [];
    var response = await Api.get(
      url: Api.getNotificationListApi,
      queryParameters: body,
    );

    if (!response[Api.error]) {
      List list = response['data'];
      notificationList =
          list.map((model) => NotificationData.fromJson(model)).toList();
    } else {
      throw CustomException(response[Api.message]);
    }
    return notificationList;
  }
}
