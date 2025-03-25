import 'package:tlobni/data/repositories/report_item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ItemReportState {}

class ItemReportInitial extends ItemReportState {}

class ItemReportInProgress extends ItemReportState {}

class ItemReportInSuccess extends ItemReportState {
  final String responseMessage;

  ItemReportInSuccess(this.responseMessage);
}

class ItemReportFailure extends ItemReportState {
  final dynamic error;

  ItemReportFailure(this.error);
}

class ItemReportCubit extends Cubit<ItemReportState> {
  ItemReportCubit() : super(ItemReportInitial());
  ReportItemRepository repository = ReportItemRepository();

  void report({
    required int item_id,
    required int reason_id,
    String? message,
  }) async {
    try {
      emit(ItemReportInProgress());

      Map response = await repository.reportItem(
          reasonId: reason_id, itemId: item_id, message: message);

      if (response['error'] == false) {
        emit(ItemReportInSuccess(response['message']));
      } else {
        emit(ItemReportFailure(response['message']));
      }
    } catch (e) {
      emit(ItemReportFailure(e.toString()));
    }
  }
}
