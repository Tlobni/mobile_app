import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/transaction_model.dart';
import 'package:eClassify/data/repositories/transaction.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchTransactionsState {}

class FetchTransactionsInitial extends FetchTransactionsState {}

class FetchTransactionsInProgress extends FetchTransactionsState {}

class FetchTransactionsSuccess extends FetchTransactionsState {
  final bool isLoadingMore;
  final bool loadingMoreError;
  final List<TransactionModel> transactionModel;
  final int page;
  final int total;

  FetchTransactionsSuccess({
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.transactionModel,
    required this.page,
    required this.total,
  });

  FetchTransactionsSuccess copyWith({
    bool? isLoadingMore,
    bool? loadingMoreError,
    List<TransactionModel>? transactionModel,
    int? page,
    int? total,
  }) {
    return FetchTransactionsSuccess(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      transactionModel: transactionModel ?? this.transactionModel,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchTransactionsFailure extends FetchTransactionsState {
  final String errorMessage;

  FetchTransactionsFailure(this.errorMessage);
}

class FetchTransactionsCubit extends Cubit<FetchTransactionsState> {
  FetchTransactionsCubit() : super(FetchTransactionsInitial());

  final TransactionRepository _transactionRepository = TransactionRepository();

  Future<void> fetchTransactions() async {
    try {
      emit(FetchTransactionsInProgress());

      DataOutput<TransactionModel> result =
          await _transactionRepository.fetchTransactions(page: 1);

      emit(FetchTransactionsSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          transactionModel: result.modelList,
          page: 1,
          total: result.total));
    } catch (e) {
      if (!isClosed) {
        emit(FetchTransactionsFailure(e.toString()));
      }
    }
  }

  Future<void> fetchTransactionsMore() async {
    try {
      if (state is FetchTransactionsSuccess) {
        if ((state as FetchTransactionsSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchTransactionsSuccess).copyWith(isLoadingMore: true));
        DataOutput<TransactionModel> result =
            await _transactionRepository.fetchTransactions(
          page: (state as FetchTransactionsSuccess).page + 1,
        );

        FetchTransactionsSuccess transactionModelState =
            (state as FetchTransactionsSuccess);
        transactionModelState.transactionModel.addAll(result.modelList);
        emit(FetchTransactionsSuccess(
            isLoadingMore: false,
            loadingMoreError: false,
            transactionModel: transactionModelState.transactionModel,
            page: (state as FetchTransactionsSuccess).page + 1,
            total: result.total));
      }
    } catch (e) {
      emit((state as FetchTransactionsSuccess)
          .copyWith(isLoadingMore: false, loadingMoreError: true));
    }
  }

  bool hasMoreData() {
    if (state is FetchTransactionsSuccess) {
      return (state as FetchTransactionsSuccess).transactionModel.length <
          (state as FetchTransactionsSuccess).total;
    }
    return false;
  }
}
