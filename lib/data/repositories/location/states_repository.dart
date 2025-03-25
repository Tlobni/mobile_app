import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/location/states_model.dart';
import 'package:tlobni/utils/api.dart';

class StatesRepository {
  Future<DataOutput<StatesModel>> fetchStates(
      {required int page, required int countryId, String? search}) async {
    Map<String, dynamic> parameters = {
      Api.page: page,
      Api.countryId: countryId,
      if (search != null) Api.search: search
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getStatesApi,
      queryParameters: parameters,
      useBaseUrl: true,
    );

    List<StatesModel> modelList = (response['data']['data'] as List)
        .map((e) => StatesModel.fromJson(e))
        .toList();

    return DataOutput<StatesModel>(
      total: response['data']['total'] ?? 0,
      modelList: modelList,
    );
  }
}
