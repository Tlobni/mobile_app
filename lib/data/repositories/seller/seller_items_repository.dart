import 'package:tlobni/utils/api.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';

class SellerItemsRepository {
  Future<DataOutput<ItemModel>> fetchSellerItemsAllItems(
      {required int page, required int sellerId}) async {
    try {
      Map<String, dynamic> parameters = {"page": page, "user_id": sellerId};

      Map<String, dynamic> response =
          await Api.get(url: Api.getItemApi, queryParameters: parameters);
      List<ItemModel> items = (response['data']['data'] as List)
          .map((e) => ItemModel.fromJson(e))
          .toList();

      return DataOutput(
          total: response['data']['total'] ?? 0, modelList: items);
    } catch (error) {
      rethrow;
    }
  }
}
