import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/utils/api.dart';
import 'package:path/path.dart' as path;

class ItemRepository {
  Future<ItemModel> createItem(
    Map<String, dynamic> itemDetails,
    File mainImage,
    List<File>? otherImages,
  ) async {
    try {
      Map<String, dynamic> parameters = {};
      parameters.addAll(itemDetails);

      // Main image
      //MultipartFile image = await MultipartFile.fromFile(mainImage.path);
      MultipartFile image = await MultipartFile.fromFile(mainImage.path,
          filename: path.basename(mainImage.path));

      if (otherImages != null && otherImages.isNotEmpty) {
        List<Future<MultipartFile>> futures = otherImages.map((imageFile) {
          //return MultipartFile.fromFile(imageFile.path);
          return MultipartFile.fromFile(imageFile.path,
              filename: path.basename(imageFile.path));
        }).toList();

        List<MultipartFile> galleryImages = await Future.wait(futures);

        if (galleryImages.isNotEmpty) {
          parameters["gallery_images"] = galleryImages;
        }
      }

      parameters.addAll({
        "image": image,
        "show_only_to_premium": 1,
      });

      Map<String, dynamic> response = await Api.post(
        url: Api.addItemApi,
        parameter: parameters, /* useAuthToken: true*/
      );

      return ItemModel.fromJson(response['data'][0]);
    } catch (e) {
      rethrow;
    }
  }

  Future<DataOutput<ItemModel>> fetchMyFeaturedItems({int? page}) async {
    try {
      Map<String, dynamic> parameters = {"status": "featured", "page": page};

      Map<String, dynamic> response = await Api.get(
        url: Api.getMyItemApi,
        queryParameters: parameters, /*useAuthToken: true*/
      );
      List<ItemModel> itemList = (response['data']['data'] as List)
          .map((element) => ItemModel.fromJson(element))
          .toList();

      return DataOutput(
          total: response['data']['total'] ?? 0, modelList: itemList);
    } catch (e) {
      rethrow;
    }
  }

  Future<DataOutput<ItemModel>> fetchMyItems(
      {String? getItemsWithStatus, int? page}) async {
    try {
      Map<String, dynamic> parameters = {
        if (getItemsWithStatus != null) "status": getItemsWithStatus,
        if (page != null) Api.page: page
      };

      if (parameters['status'] == "") parameters.remove('status');
      Map<String, dynamic> response = await Api.get(
        url: Api.getMyItemApi,
        queryParameters: parameters, /*useAuthToken: true*/
      );
      List<ItemModel> itemList = (response['data']['data'] as List)
          .map((element) => ItemModel.fromJson(element))
          .toList();

      return DataOutput(
          total: response['data']['total'] ?? 0, modelList: itemList);
    } catch (e) {
      rethrow;
    }
  }

  Future<DataOutput<ItemModel>> fetchItemFromItemId(int id) async {
    Map<String, dynamic> parameters = {
      Api.id: id,
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getItemApi,
      queryParameters: parameters,
    );

    List<ItemModel> modelList =
        (response['data'] as List).map((e) => ItemModel.fromJson(e)).toList();

    return DataOutput(total: modelList.length, modelList: modelList);
  }

  Future<DataOutput<ItemModel>> fetchItemFromItemSlug(String slug) async {
    Map<String, dynamic> parameters = {
      "slug": slug,
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getItemApi,
      queryParameters: parameters,
    );

    List<ItemModel> modelList = (response['data']['data'] as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: modelList.length, modelList: modelList);
  }

  Future<Map> changeMyItemStatus(
      {required int itemId, required String status, int? userId}) async {
    Map response = await Api.post(url: Api.updateItemStatusApi, parameter: {
      Api.status: status,
      Api.itemId: itemId,
      Api.soldTo: userId
    });
    return response;
  }

  Future<Map> createFeaturedAds({required int itemId}) async {
    Map response = await Api.post(url: Api.makeItemFeaturedApi, parameter: {
      "item_id": itemId,
    });
    return response;
  }

  Future<DataOutput<ItemModel>> fetchItemFromCatId(
      {required int categoryId,
      required int page,
      String? search,
      String? sortBy,
      String? country,
      String? state,
      String? city,
      int? areaId,
      ItemFilterModel? filter}) async {
    Map<String, dynamic> parameters = {
      Api.categoryId: categoryId,
      Api.page: page,
    };

    if (filter != null) {
      var filterMap = filter.toMap();
      print("DEBUG: Filter map before adding to parameters: $filterMap");
      print("DEBUG: Service type in filter: ${filter.serviceType}");
      print("DEBUG: Gender in filter: ${filter.gender}");

      // Check if serviceType is present and not null
      if (filter.serviceType != null) {
        // Ensure provider_item_type is explicitly set in parameters
        parameters['provider_item_type'] = filter.serviceType;
        print(
            "DEBUG: Explicitly set provider_item_type to ${filter.serviceType}");
      }

      // Check if gender is present and not null
      if (filter.gender != null) {
        // Ensure gender is explicitly set in parameters
        parameters['gender'] = filter.gender;
        print("DEBUG: Explicitly set gender to ${filter.gender}");
      }

      parameters.addAll(filterMap);
      print("DEBUG: Final parameters being sent to API: $parameters");

      // If radius is present, include latitude and longitude
      // and remove location-related fields
      if (filter.radius != null) {
        if (filter.latitude != null && filter.longitude != null) {
          parameters['latitude'] = filter.latitude;
          parameters['longitude'] = filter.longitude;
        }

        // Remove location-related fields when radius is provided
        parameters.remove('city');
        parameters.remove('area');
        parameters.remove('area_id');
        parameters.remove('country');
        parameters.remove('state');
      } else {
        // If radius is not present, include other location-related parameters
        if (city != null && city != "") parameters['city'] = city;
        if (areaId != null) parameters['area_id'] = areaId;
        if (country != null && country != "") parameters['country'] = country;
        if (state != null && state != "") parameters['state'] = state;
      }

      if (filter.areaId == null) {
        parameters.remove('area_id');
      }

      parameters.remove('area');

      // Add custom fields separately to the parameters
      if (filter.customFields != null) {
        filter.customFields!.forEach((key, value) {
          if (value is List) {
            parameters[key] = value.map((v) => v.toString()).join(',');
          } else {
            parameters[key] = value.toString();
          }
        });
      }
    }

    if (search != null) {
      parameters[Api.search] = search;
    }

    if (sortBy != null) {
      parameters[Api.sortBy] = sortBy;
    }

    Map<String, dynamic> response =
        await Api.get(url: Api.getItemApi, queryParameters: parameters);

    List<ItemModel> items = (response['data']['data'] as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: response['data']['total'] ?? 0, modelList: items);
  }

/*  Future<DataOutput<ItemModel>> fetchItemFromCatId(
      {required int categoryId,
      required int page,
      String? search,
      String? sortBy,
      String? country,
      String? state,
      String? city,
      int? areaId,
      ItemFilterModel? filter}) async {
    Map<String, dynamic> parameters = {
      Api.categoryId: categoryId,
      Api.page: page,
      if (city != null && city != "") 'city': city,
      if (areaId != null && areaId != "") 'area_id': areaId,
      if (country != null && country != "") 'country': country,
      if (state != null && state != "") 'state': state,
    };

    if (filter != null) {
      parameters.addAll(filter.toMap());

      if (filter.areaId == null) {
        parameters.remove('area_id');
      }

      parameters.remove('area');

      // Add custom fields separately to the parameters
      if (filter.customFields != null) {
        filter.customFields!.forEach((key, value) {
          if (value is List) {
            parameters[key] = value.map((v) => v.toString()).join(',');
          } else {
            parameters[key] = value.toString();
          }
        });
      }
    }

    if (search != null) {
      parameters[Api.search] = search;
    }

    if (sortBy != null) {
      parameters[Api.sortBy] = sortBy;
    }

    Map<String, dynamic> response =
        await Api.get(url: Api.getItemApi, queryParameters: parameters);

    List<ItemModel> items = (response['data']['data'] as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: response['data']['total'] ?? 0, modelList: items);
  }*/

  Future<DataOutput<ItemModel>> fetchPopularItems(
      {required String sortBy, required int page}) async {
    Map<String, dynamic> parameters = {Api.sortBy: sortBy, Api.page: page};

    Map<String, dynamic> response =
        await Api.get(url: Api.getItemApi, queryParameters: parameters);

    List<ItemModel> items = (response['data']['data'] as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: response['data']['total'] ?? 0, modelList: items);
  }

  Future<ItemModel> editItem(
    Map<String, dynamic> itemDetails,
    File? mainImage,
    List<File>? otherImages,
  ) async {
    Map<String, dynamic> parameters = {};
    parameters.addAll(itemDetails);

    if (mainImage != null) {
      MultipartFile image = await MultipartFile.fromFile(mainImage.path,
          filename: path.basename(mainImage.path));
      parameters['image'] = image;
    }

    if (otherImages != null && otherImages.isNotEmpty) {
      List<Future<MultipartFile>> futures = otherImages.map((imageFile) {
        return MultipartFile.fromFile(imageFile.path,
            filename: path.basename(imageFile.path));
      }).toList();

      List<MultipartFile> galleryImages = await Future.wait(futures);

      if (galleryImages.isNotEmpty) {
        parameters["gallery_images"] = galleryImages;
      }
    }

    Map<String, dynamic> response = await Api.post(
      url: Api.updateItemApi,
      parameter: parameters, /* useAuthToken: true*/
    );

    return ItemModel.fromJson(response['data'][0]);
  }

  Future<void> deleteItem(int id) async {
    await Api.post(
      url: Api.deleteItemApi,
      parameter: {Api.id: id}, /* useAuthToken: true*/
    );
  }

  Future<void> itemTotalClick(int id) async {
    await Api.post(url: Api.setItemTotalClickApi, parameter: {Api.itemId: id});
  }

  Future<Map> makeAnOfferItem(int id, double? amount) async {
    Map response = await Api.post(
        url: Api.itemOfferApi,
        parameter: {Api.itemId: id, if (amount != null) Api.amount: amount});
    return response;
  }

  Future<DataOutput<ItemModel>> searchItem(
      String query, ItemFilterModel? filter,
      {required int page}) async {
    Map<String, dynamic> parameters = {
      Api.search: query,
      Api.page: page,
    };

    if (filter != null) {
      print("DEBUG SEARCH: Filter service type: ${filter.serviceType}");
      print("DEBUG SEARCH: Filter gender: ${filter.gender}");
      var filterMap = filter.toMap();
      print("DEBUG SEARCH: Filter map: $filterMap");

      // Check if serviceType is present and not null
      if (filter.serviceType != null) {
        // Ensure provider_item_type is explicitly set in parameters
        parameters['provider_item_type'] = filter.serviceType;
        print(
            "DEBUG SEARCH: Explicitly set provider_item_type to ${filter.serviceType}");
      }

      // Check if gender is present and not null
      if (filter.gender != null) {
        // Ensure gender is explicitly set in parameters
        parameters['gender'] = filter.gender;
        print("DEBUG SEARCH: Explicitly set gender to ${filter.gender}");
      }

      parameters.addAll(filterMap);

      if (filter.areaId == null) {
        parameters.remove('area_id');
      }
      parameters.remove('area');
      if (filter.customFields != null) {
        parameters.addAll(filter.customFields!);
      }

      print("DEBUG SEARCH: Final parameters: $parameters");
    }

    Map<String, dynamic> response =
        await Api.get(url: Api.getItemApi, queryParameters: parameters);

    List<ItemModel> items = (response['data']['data'] as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: response['data']['total'] ?? 0, modelList: items);
  }
}
