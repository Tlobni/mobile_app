import 'package:tlobni/data/model/home/home_screen_section.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';

class HomeRepository {
  Future<List<HomeScreenSection>> fetchHome(
      {String? country, String? state, String? city, int? areaId}) async {
    try {
      Map<String, dynamic> parameters = {
        if (city != null && city != "") 'city': city,
        if (areaId != null && areaId != "") 'area_id': areaId,
        if (country != null && country != "") 'country': country,
        if (state != null && state != "") 'state': state,
      };

      Map<String, dynamic> response = await Api.get(
          url: Api.getFeaturedSectionApi, queryParameters: parameters);
      List<HomeScreenSection> homeScreenDataList =
          (response['data'] as List).map((element) {
        return HomeScreenSection.fromJson(element);
      }).toList();

      return homeScreenDataList;
    } catch (e) {
      rethrow;
    }
  }

  Future<DataOutput<ItemModel>> fetchHomeAllItems(
      {required int page,
      String? country,
      String? state,
      String? city,
      double? latitude,
      double? longitude,
      int? areaId,
      int? radius,
      String? postType,
      bool? isFeatured}) async {
    try {
      Map<String, dynamic> parameters = {
        "page": page,
        if (radius == null) ...{
          if (city != null && city != "") 'city': city,
          if (areaId != null && areaId != "") 'area_id': areaId,
          if (country != null && country != "") 'country': country,
          if (state != null && state != "") 'state': state,
        },
        if (radius != null && radius != "") 'radius': radius,
        if (latitude != null && latitude != "") 'latitude': latitude,
        if (longitude != null && longitude != "") 'longitude': longitude,
        if (postType != null && postType != "") 'post_type': postType,
        if (isFeatured != null && isFeatured) 'is_feature': "1",
        "sort_by": "new-to-old"
      };

      Map<String, dynamic> response =
          await Api.get(url: Api.getItemApi, queryParameters: parameters);
      List<ItemModel> items = (response['data']['data'] as List)
          .map((e) => ItemModel.fromJson(e))
          .toList();

      return DataOutput(
          total: response['data']['total'] ?? 0, modelList: items);
    } catch (error) {
      rethrow;
    }
  }

  Future<DataOutput<ItemModel>> fetchSectionItems(
      {required int page,
      required int sectionId,
      String? country,
      String? state,
      String? city,
      int? areaId,
      String? postType,
      bool? isFeatured,
      String? endpoint,
      Map<String, dynamic>? filter}) async {
    try {
      Map<String, dynamic> parameters = {
        "page": page,
        "featured_section_id": sectionId,
        if (city != null && city != "") 'city': city,
        if (areaId != null && areaId != "") 'area_id': areaId,
        if (country != null && country != "") 'country': country,
        if (state != null && state != "") 'state': state,
        if (postType != null && postType != "") 'post_type': postType,
        if (isFeatured != null && isFeatured) 'is_feature': "1",
        if (filter != null) ...filter,
      };

      print(
          'Fetching section items with endpoint: ${endpoint ?? Api.getItemApi}');
      print('Parameters: $parameters');

      Map<String, dynamic> response = await Api.get(
          url: endpoint ?? Api.getItemApi, queryParameters: parameters);

      print('Response structure: ${response.keys.join(', ')}');
      if (response['data'] != null) {
        print(
            'Data structure: ${response['data'] is List ? 'List' : response['data'].keys.join(', ')}');
      }

      List<ItemModel> items = [];
      if (response['data'] is List) {
        items = (response['data'] as List)
            .map((e) => ItemModel.fromJson(e))
            .toList();
      } else if (response['data']['data'] is List) {
        items = (response['data']['data'] as List)
            .map((e) => ItemModel.fromJson(e))
            .toList();
      } else if (response['data']['items'] is List) {
        items = (response['data']['items'] as List)
            .map((e) => ItemModel.fromJson(e))
            .toList();
      }

      print('Found ${items.length} items');
      return DataOutput(
          total: response['data']['total'] ?? items.length, modelList: items);
    } catch (error) {
      print('Error fetching section items: $error');
      rethrow;
    }
  }
}
