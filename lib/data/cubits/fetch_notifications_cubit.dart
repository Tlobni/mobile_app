import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/notification_data.dart';
import 'package:tlobni/data/repositories/notifications_repository_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchNotificationsState {}

class FetchNotificationsInitial extends FetchNotificationsState {}

class FetchNotificationsInProgress extends FetchNotificationsState {}

class FetchNotificationsSuccess extends FetchNotificationsState {
  final bool isLoadingMore;
  final bool loadingMoreError;
  final List<NotificationData> notificationdata;
  final int page;
  final int total;

  FetchNotificationsSuccess({
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.notificationdata,
    required this.page,
    required this.total,
  });

  FetchNotificationsSuccess copyWith({
    bool? isLoadingMore,
    bool? loadingMoreError,
    List<NotificationData>? notificationdata,
    int? page,
    int? total,
  }) {
    return FetchNotificationsSuccess(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      notificationdata: notificationdata ?? this.notificationdata,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchNotificationsFailure extends FetchNotificationsState {
  final dynamic errorMessage;

  FetchNotificationsFailure(this.errorMessage);
}

class FetchNotificationsCubit extends Cubit<FetchNotificationsState> {
  FetchNotificationsCubit() : super(FetchNotificationsInitial());

  final NotificationsRepository _notificationsRepository =
      NotificationsRepository();

  Future fetchNotifications() async {
    try {
      emit(FetchNotificationsInProgress());

      DataOutput<NotificationData> result =
          await _notificationsRepository.fetchNotifications(page: 1);
      emit(FetchNotificationsSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          notificationdata: result.modelList,
          page: 1,
          total: result.total));
    } catch (e) {
      emit(FetchNotificationsFailure(e));
    }
  }

  Future<void> fetchNotificationsMore() async {
    try {
      if (state is FetchNotificationsSuccess) {
        if ((state as FetchNotificationsSuccess).isLoadingMore) {
          return;
        }
        emit(
            (state as FetchNotificationsSuccess).copyWith(isLoadingMore: true));
        DataOutput<NotificationData> result =
            await _notificationsRepository.fetchNotifications(
          page: (state as FetchNotificationsSuccess).page + 1,
        );

        FetchNotificationsSuccess notificationdataState =
            (state as FetchNotificationsSuccess);
        notificationdataState.notificationdata.addAll(result.modelList);
        emit(FetchNotificationsSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            notificationdata: notificationdataState.notificationdata,
            page: (state as FetchNotificationsSuccess).page + 1,
            total: result.total));
      }
    } catch (e) {
      emit((state as FetchNotificationsSuccess)
          .copyWith(isLoadingMore: false, loadingMoreError: true));
    }
  }

  bool hasMoreData() {
    if (state is FetchNotificationsSuccess) {
      return (state as FetchNotificationsSuccess).notificationdata.length <
          (state as FetchNotificationsSuccess).total;
    }
    return false;
  }
}
