import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/report_item/reason_model.dart';
import 'package:eClassify/data/repositories/report_item_repository.dart';
import 'package:eClassify/settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchItemReportReasonsListState {}

class FetchItemReportReasonsInitial extends FetchItemReportReasonsListState {}

class FetchItemReportReasonsInProgress
    extends FetchItemReportReasonsListState {}

class FetchItemReportReasonsSuccess extends FetchItemReportReasonsListState {
  final int total;
  final List<ReportReason> reasons;

  FetchItemReportReasonsSuccess({required this.total, required this.reasons});

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'reasons': reasons.map((e) => e.toMap()).toList(),
    };
  }

  factory FetchItemReportReasonsSuccess.fromMap(Map<String, dynamic> map) {
    return FetchItemReportReasonsSuccess(
      total: map['total'] as int,
      reasons:
          (map['reasons'] as List).map((e) => ReportReason.fromMap(e)).toList(),
    );
  }
}

class FetchItemReportReasonsFailure extends FetchItemReportReasonsListState {
  final dynamic error;

  FetchItemReportReasonsFailure(this.error);
}

class FetchItemReportReasonsListCubit
    extends Cubit<FetchItemReportReasonsListState> {
  FetchItemReportReasonsListCubit() : super(FetchItemReportReasonsInitial());
  final ReportItemRepository _repository = ReportItemRepository();
  void fetch({bool? forceRefresh}) async {
    try {
      if (forceRefresh != true) {
        if (state is FetchItemReportReasonsSuccess) {
          // WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          await Future.delayed(
              const Duration(seconds: AppSettings.hiddenAPIProcessDelay));
          // });
        } else {
          emit(FetchItemReportReasonsInProgress());
        }
      } else {
        emit(FetchItemReportReasonsInProgress());
      }

      if (forceRefresh == true) {
        DataOutput<ReportReason> result =
            await _repository.fetchReportReasonsList();

        result.modelList.add(ReportReason(id: -10, reason: "Other"));

        emit(FetchItemReportReasonsSuccess(
          reasons: result.modelList,
          total: result.total,
        ));
      } else {
        if (state is! FetchItemReportReasonsSuccess) {
          DataOutput<ReportReason> result =
              await _repository.fetchReportReasonsList();

          result.modelList.add(ReportReason(id: -10, reason: "Other"));

          emit(FetchItemReportReasonsSuccess(
            reasons: result.modelList,
            total: result.total,
          ));
        }
      }

      // emit(FetchItemReportReasonsInProgress());
    } catch (e) {
      emit(FetchItemReportReasonsFailure(e));
    }
  }

  List<ReportReason>? getList() {
    if (state is FetchItemReportReasonsSuccess) {
      return (state as FetchItemReportReasonsSuccess).reasons;
    }
    return null;
  }

  FetchItemReportReasonsListState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['cubit_state'] == "FetchItemReportReasonsSuccess") {
        FetchItemReportReasonsSuccess fetchItemReportReasonsSuccess =
            FetchItemReportReasonsSuccess.fromMap(json);

        return fetchItemReportReasonsSuccess;
      }
    } catch (e) {}
    return null;
  }

  Map<String, dynamic>? toJson(FetchItemReportReasonsListState state) {
    try {
      if (state is FetchItemReportReasonsSuccess) {
        Map<String, dynamic> mapped = state.toMap();
        mapped['cubit_state'] = "FetchItemReportReasonsSuccess";
        return mapped;
      }
    } catch (e) {}

    return null;
  }
}
