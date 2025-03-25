import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/transaction_model.dart';
import 'package:tlobni/utils/api.dart';

class TransactionRepository {
  Future<DataOutput<TransactionModel>> fetchTransactions(
      {required int page}) async {
    Map<String, dynamic> parameters = {
      //Api.page:page
    };

    Map<String, dynamic> response = await Api.get(
        url: Api.getPaymentDetailsApi, queryParameters: parameters);

    List<TransactionModel> transactionList = (response['data'] as List)
        .map((e) => TransactionModel.fromJson(e))
        .toList();

    return DataOutput<TransactionModel>(
        total: transactionList.length, modelList: transactionList);
  }
}
