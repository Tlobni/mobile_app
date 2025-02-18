import 'package:eClassify/data/model/blog_model.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/utils/api.dart';

class BlogsRepository {
  Future<DataOutput<BlogModel>> fetchBlogs({required int page}) async {
    Map<String, dynamic> parameters = {
      Api.page: page,
    };

    Map<String, dynamic> result =
        await Api.get(url: Api.getBlogApi, queryParameters: parameters);

    List<BlogModel> modelList = (result['data']['data'] as List)
        .map((element) => BlogModel.fromJson(element))
        .toList();

    return DataOutput<BlogModel>(
        total: result['data']['total'] ?? 0, modelList: modelList);
  }
}
