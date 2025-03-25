import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/location/area_model.dart';
import 'package:tlobni/utils/api.dart';

class AreasRepository {
  Future<DataOutput<AreaModel>> fetchAreas(
      {required int page, required int cityId, String? search}) async {
    Map<String, dynamic> parameters = {
      Api.page: page,
      Api.cityId: cityId,
      if (search != null) Api.search: search
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getAreasApi,
      queryParameters: parameters,
      useBaseUrl: true,
    );

    List<AreaModel> modelList = (response['data']['data'] as List)
        .map((e) => AreaModel.fromJson(e))
        .toList();

    return DataOutput<AreaModel>(
      total: response['data']['total'] ?? 0,
      modelList: modelList,
    );
  }
}
