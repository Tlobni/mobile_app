import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/location/countries_model.dart';
import 'package:eClassify/utils/api.dart';

class CountriesRepository {
  Future<DataOutput<CountriesModel>> fetchCountries(
      {required int page, String? search}) async {
    Map<String, dynamic> parameters = {
      Api.page: page,
      if (search != null) Api.search: search
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getCountriesApi,
      queryParameters: parameters,
      useBaseUrl: true,
    );

    List<CountriesModel> modelList = (response['data']['data'] as List)
        .map((e) => CountriesModel.fromJson(e))
        .toList();

    return DataOutput<CountriesModel>(
      total: response['data']['total'] ?? 0,
      modelList: modelList,
    );
  }
}
