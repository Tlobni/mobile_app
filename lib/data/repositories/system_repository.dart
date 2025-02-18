import 'package:eClassify/utils/api.dart';

class SystemRepository {
  Future<Map> fetchSystemSettings() async {
    Map<String, dynamic> parameters = {};

    Map<String, dynamic> response = await Api.get(
      queryParameters: parameters,
      url: Api.getSystemSettingsApi,
    );

    return response;
  }
}
