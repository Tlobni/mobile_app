import 'package:eClassify/data/model/custom_field/custom_field_model.dart';
import 'package:eClassify/utils/api.dart';

class CustomFieldRepository {
  Future<List<CustomFieldModel>> getCustomFields(String categoryIds) async {
    try {
      Map<String, dynamic> parameters = {
        Api.categoryIds: categoryIds,
      };

      Map<String, dynamic> response = await Api.get(
          url: Api.getCustomFieldsApi, queryParameters: parameters);

      List<CustomFieldModel> modelList = (response['data'] as List)
          .map((e) => CustomFieldModel.fromMap(e))
          .toList();

      return modelList;
    } catch (e) {
      throw "$e";
    }
  }
}
