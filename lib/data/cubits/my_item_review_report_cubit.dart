import 'package:eClassify/data/repositories/my_item_report_review_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AddMyItemReviewReportState {}

class AddMyItemReviewReportInitial extends AddMyItemReviewReportState {}

class AddMyItemReviewReportInProgress extends AddMyItemReviewReportState {}

class AddMyItemReviewReportInSuccess extends AddMyItemReviewReportState {
  final String responseMessage;

  AddMyItemReviewReportInSuccess(this.responseMessage);
}

class AddMyItemReviewReportFailure extends AddMyItemReviewReportState {
  final dynamic error;

  AddMyItemReviewReportFailure(this.error);
}

class AddMyItemReviewReportCubit extends Cubit<AddMyItemReviewReportState> {
  AddMyItemReviewReportCubit() : super(AddMyItemReviewReportInitial());
  AddMyItemReportReviewRepository repository =
      AddMyItemReportReviewRepository();

  void addMyItemReviewReport(
      {required int sellerReviewId, required String reportReason}) async {
    emit(AddMyItemReviewReportInProgress());

    repository
        .addMyItemReportReview(
            reportReason: reportReason, sellerReviewId: sellerReviewId)
        .then((value) {
      emit(AddMyItemReviewReportInSuccess(value['message']));
    }).catchError((e) {
      emit(AddMyItemReviewReportFailure(e.toString()));
    });
  }
}
