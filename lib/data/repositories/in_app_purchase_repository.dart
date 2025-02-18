import 'package:eClassify/utils/api.dart';

class InAppPurchaseRepository {
  Future<Map> inAppPurchases(
      {required String purchaseToken,
      required String method,
      required int packageId}) async {
    Map<String, dynamic> parameters = {
      "purchase_token": purchaseToken,
      "payment_method": method,
      "package_id": packageId
    };

    Map<String, dynamic> response = await Api.post(
      parameter: parameters,
      url: Api.inAppPurchaseApi,
    );

    return response;
  }
}
