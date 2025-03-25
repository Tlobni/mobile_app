import 'package:tlobni/data/model/custom_field/custom_field_model.dart';
import 'package:tlobni/data/model/verification_request_model.dart';
import 'package:tlobni/utils/api.dart';

class SellerVerificationFieldRepository {
  Future<List<VerificationFieldModel>> getSellerVerificationFields() async {
    try {
      Map<String, dynamic> parameters = {};

      Map<String, dynamic> response = await Api.get(
          url: Api.getVerificationFieldApi, queryParameters: parameters);

      List<VerificationFieldModel> modelList = (response['data'] as List)
          .map((e) => VerificationFieldModel.fromMap(e))
          .toList();

      return modelList;
    } catch (e) {
      throw "$e";
    }
  }

  Future<Map> sendVerificationField(
      {required Map<String, dynamic> data}) async {
    try {
      Map response =
          await Api.post(url: Api.sendVerificationRequestApi, parameter: data);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<VerificationRequestModel> getVerificationRequest() async {
    try {
      Map<String, dynamic> parameters = {};

      Map<String, dynamic> response = await Api.get(
          url: Api.getVerificationRequestApi, queryParameters: parameters);

      VerificationRequestModel model =
          VerificationRequestModel.fromJson(response['data']);

      return model;
    } catch (e) {
      throw "$e";
    }
  }
}
