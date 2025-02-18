import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/user_model.dart';
import 'package:eClassify/utils/api.dart';

class ItemBuyerRepository {
  Future<DataOutput<BuyerModel>> fetchItemBuyerList(int itemId) async {
    Map<String, dynamic> response = await Api.get(
        url: Api.getItemBuyerListApi, queryParameters: {Api.itemId: itemId});

    List<BuyerModel> modelList = (response['data'] as List).map(
      (e) {
        return BuyerModel.fromJson(e);
      },
    ).toList();

    return DataOutput(total: modelList.length, modelList: modelList);
  }
}
