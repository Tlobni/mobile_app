import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eClassify/utils/api.dart';

class AdvertisementRepository {
  Future<Map<String, dynamic>> create({
    required String type,
    required String itemId,
    required String packageId,
    File? image,
  }) async {
    Map<String, dynamic> parameters = {
      Api.packageId: packageId,
      Api.itemId: itemId,
      Api.type: type
    };
    if (image != null) {
      parameters[Api.image] = await MultipartFile.fromFile(image.path);
    }

    return await Api.post(
        url: Api.storeAdvertisementApi, parameter: parameters);
  }

  Future deleteAdvertisment(dynamic id) async {
    await Api.post(url: Api.deleteAdvertisementApi, parameter: {Api.id: id});
  }

  Future<Map> assignFreePackages({required int packageId}) async {
    Map response = await Api.post(
      url: Api.assignFreePackageApi,
      parameter: {Api.packageId: packageId},
    );
    return response;
  }

  Future<Map> fetchUserPackageLimit({required String packageType}) async {
    Map response = await Api.get(
      url: Api.getLimitsOfPackageApi,
      queryParameters: {"package_type": packageType},
    );
    return response;
  }

  Future<Map> getPaymentIntent(
      {required int packageId, required String paymentMethod}) async {
    Map<String, dynamic> parameters = {
      "package_id": packageId,
      "payment_method": paymentMethod,
      "platform": Platform.isAndroid ? "android" : "ios",
      "force_pending": true,
      if (paymentMethod == "Paystack") "platform_type": "app"
    };

    Map<String, dynamic> response = await Api.post(
      url: Api.getPaymentIntentApi,
      parameter: parameters,
    );

    return response;
  }
}
