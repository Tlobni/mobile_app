import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/utils/api.dart';

class CategoryRepository {
  Future<DataOutput<CategoryModel>> fetchCategories({
    required int page,
    int? categoryId,
  }) async {
    try {
      Map<String, dynamic> parameters = {
        Api.page: page,
      };

      if (categoryId != null) {
        parameters[Api.categoryId] = categoryId;
      }
      Map<String, dynamic> response =
          await Api.get(url: Api.getCategoriesApi, queryParameters: parameters);

      List<CategoryModel> modelList = (response['data']['data'] as List).map(
        (e) {
          return CategoryModel.fromJson(e);
        },
      ).toList();
      return DataOutput(
          total: response['data']['total'] ?? 0, modelList: modelList);
      // return (total: response['total'] ?? 0, modelList: modelList);
    } catch (e) {
      rethrow;
    }
  }
}
