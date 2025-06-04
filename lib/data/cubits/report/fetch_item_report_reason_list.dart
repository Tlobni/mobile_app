import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/report_item/reason_model.dart';
import 'package:tlobni/data/repositories/report_item_repository.dart';
import 'package:tlobni/settings.dart';

abstract class FetchItemReportReasonsListState {}

class FetchItemReportReasonsInitial extends FetchItemReportReasonsListState {}

class FetchItemReportReasonsInProgress extends FetchItemReportReasonsListState {}

class FetchItemReportReasonsSuccess extends FetchItemReportReasonsListState {
  final int total;
  final List<ReportReason> reasons;
  final int selectedId;

  FetchItemReportReasonsSuccess({
    required this.total,
    required this.reasons,
    required this.selectedId,
  });

  FetchItemReportReasonsSuccess copyWith({
    int? total,
    List<ReportReason>? reasons,
    int? selectedId,
  }) {
    return FetchItemReportReasonsSuccess(
      total: total ?? this.total,
      reasons: reasons ?? this.reasons,
      selectedId: selectedId ?? this.selectedId,
    );
  }
}

class FetchItemReportReasonsFailure extends FetchItemReportReasonsListState {
  final dynamic error;

  FetchItemReportReasonsFailure(this.error);
}

class FetchItemReportReasonsListCubit extends Cubit<FetchItemReportReasonsListState> {
  FetchItemReportReasonsListCubit() : super(FetchItemReportReasonsInitial());
  final ReportItemRepository _repository = ReportItemRepository();
  Future<void> fetch({bool? forceRefresh}) async {
    try {
      if (forceRefresh != true) {
        if (state is FetchItemReportReasonsSuccess) {
          // WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          await Future.delayed(const Duration(seconds: AppSettings.hiddenAPIProcessDelay));
          // });
        } else {
          emit(FetchItemReportReasonsInProgress());
        }
      } else {
        emit(FetchItemReportReasonsInProgress());
      }

      if (forceRefresh == true) {
        DataOutput<ReportReason> result = await _repository.fetchReportReasonsList();

        result.modelList.add(ReportReason(id: -10, reason: "Other"));

        emit(FetchItemReportReasonsSuccess(
          reasons: result.modelList,
          total: result.total,
          selectedId: result.modelList.first.id,
        ));
      } else {
        if (state is! FetchItemReportReasonsSuccess) {
          DataOutput<ReportReason> result = await _repository.fetchReportReasonsList();

          result.modelList.add(ReportReason(id: -10, reason: "Other"));

          emit(FetchItemReportReasonsSuccess(
            reasons: result.modelList,
            total: result.total,
            selectedId: result.modelList.first.id,
          ));
        }
      }

      // emit(FetchItemReportReasonsInProgress());
    } catch (e) {
      emit(FetchItemReportReasonsFailure(e));
    }
  }

  void selectId(int id) {
    if (state is FetchItemReportReasonsSuccess) {
      emit((state as FetchItemReportReasonsSuccess).copyWith(selectedId: id));
    }
  }

  List<ReportReason>? getList() {
    if (state is FetchItemReportReasonsSuccess) {
      return (state as FetchItemReportReasonsSuccess).reasons;
    }
    return null;
  }
}
