import 'package:eClassify/utils/api.dart';

class RenewItemRepositoryRepository {
  Future<Map> renewItem({required int itemId, required int packageId}) async {
    Map response = await Api.post(
      url: Api.renewItemApi,
      parameter: {Api.itemId: itemId, Api.packageId: packageId},
    );
    return response;
  }
}
