import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/faqs_model.dart';
import 'package:tlobni/data/repositories/faqs_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchFaqsState {}

class FetchFaqsInitial extends FetchFaqsState {}

class FetchFaqsInProgress extends FetchFaqsState {}

class FetchFaqsSuccess extends FetchFaqsState {
  final List<FaqsModel> faqModel;
  final int total;

  FetchFaqsSuccess({
    required this.faqModel,
    required this.total,
  });

  FetchFaqsSuccess copyWith({
    bool? isLoadingMore,
    bool? loadingMoreError,
    List<FaqsModel>? faqModel,
    int? page,
    int? total,
  }) {
    return FetchFaqsSuccess(
      faqModel: faqModel ?? this.faqModel,
      total: total ?? this.total,
    );
  }
}

class FetchFaqsFailure extends FetchFaqsState {
  final dynamic errorMessage;

  FetchFaqsFailure(this.errorMessage);
}

class FetchFaqsCubit extends Cubit<FetchFaqsState> {
  FetchFaqsCubit() : super(FetchFaqsInitial());

  final FaqsRepository _faqRepository = FaqsRepository();

  Future<void> fetchFaqs() async {
    try {
      emit(FetchFaqsInProgress());

      DataOutput<FaqsModel> result = await _faqRepository.fetchFaqs(page: 1);

      emit(
        FetchFaqsSuccess(faqModel: result.modelList, total: result.total),
      );
    } catch (e) {
      emit(FetchFaqsFailure(e));
    }
  }

  void toggleFaqExpansion(int index) {
    if (state is FetchFaqsSuccess) {
      final successState = state as FetchFaqsSuccess;
      final updatedFaqs = List<FaqsModel>.from(successState.faqModel);
      updatedFaqs[index].isExpanded = !updatedFaqs[index].isExpanded;
      emit(FetchFaqsSuccess(faqModel: updatedFaqs, total: updatedFaqs.length));
    }
  }
}
