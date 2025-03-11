import 'dart:developer';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/settings.dart';

class SystemRepository {
  Future<Map> fetchSystemSettings() async {
    Map<String, dynamic> parameters = {};

    try {
      log("Attempting to fetch system settings from: ${AppSettings.baseUrl}${Api.getSystemSettingsApi}");

      Map<String, dynamic> response = await Api.get(
        queryParameters: parameters,
        url: Api.getSystemSettingsApi,
      );

      log("Successfully fetched system settings");
      return response;
    } catch (e, stackTrace) {
      log("Error fetching system settings: $e");
      log("Stack trace: $stackTrace");

      // Check if the base URL is correctly formatted
      log("Current base URL: ${AppSettings.baseUrl}");
      log("API endpoint: ${Api.getSystemSettingsApi}");

      // Rethrow to let the cubit handle the error
      rethrow;
    }
  }
}
