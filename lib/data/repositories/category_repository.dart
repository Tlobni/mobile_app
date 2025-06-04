import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/utils/api.dart';

class CategoryRepository {
  Future<DataOutput<CategoryModel>> fetchCategories({
    required int page,
    int? categoryId,
    CategoryType? type,
  }) async {
    try {
      Map<String, dynamic> parameters = {
        Api.page: page,
      };

      if (categoryId != null) {
        parameters[Api.categoryId] = categoryId;
      }

      if (type != null) {
        parameters[Api.type] = type.value;
      }

      Map<String, dynamic> response = await Api.get(url: Api.getCategoriesApi, queryParameters: parameters);

      List<CategoryModel> modelList = (response['data']['data'] as List).map(
        (e) {
          return CategoryModel.fromJson(e);
        },
      ).toList();
      return DataOutput(total: response['data']['total'] ?? 0, modelList: modelList);
    } catch (e) {
      rethrow;
    }
  }

  Future<DataOutput<CategoryModel>> fetchAllCategories() async {
    try {
      dynamic response = await Api.get(url: Api.getAllCategoriesApi);

      print(response);

      List<CategoryModel> modelList = (response['data'] as List).map(
        (e) {
          return CategoryModel.fromJson(e);
        },
      ).toList();
      return DataOutput(total: modelList.length, modelList: modelList);
    } catch (e) {
      rethrow;
    }
  }
}
