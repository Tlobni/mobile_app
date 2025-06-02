import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/utils/api.dart';

class UserRepository {
  Future<User> fetchProvider(int id) async {
    Map<String, dynamic> response = (await Api.get(url: Api.getProvider, queryParameters: {'id': id}));
    return User.fromJson(response['data']);
  }

  Future<DataOutput<UserModel>> fetchProviders(String query, ItemFilterModel? filter, {required int page}) async {
    Map<String, dynamic> parameters = {
      'page': page,
    };

    if (query.isNotEmpty) {
      parameters['search'] = query;
    }

    if (filter != null) {
      // Add user type from filter
      parameters['type'] = filter.userType;

      // Add gender filter if provided
      if (filter.gender != null) {
        parameters['gender'] = filter.gender;
      }

      // Add category ID if provided - ENSURE this is called "category" for the API
      if (filter.categoryId != null && filter.categoryId!.isNotEmpty) {
        parameters['category'] = filter.categoryId;
        print("DEBUG: Setting category parameter to: ${filter.categoryId}");
      }

      // Add location filters
      if (filter.country != null) {
        parameters['country'] = filter.country;
      }

      if (filter.city != null) {
        parameters['city'] = filter.city;
      }

      if (filter.state != null) {
        parameters['state'] = filter.state;
      }

      // Add rating range filters
      if (filter.minRating != null) {
        parameters['rating_from'] = filter.minRating;
      }
      if (filter.maxRating != null) {
        parameters['rating_to'] = filter.maxRating;
      }

      if (filter.featuredOnly != null) {
        parameters['featured_only'] = filter.featuredOnly;
      }

      if (filter.providerSortBy != null) {
        parameters['sort_by'] = filter.providerSortBy?.jsonName;
      }
    }

    print("DEBUG: API parameters for get-users: $parameters");

    // Call the get-users API endpoint
    Map<String, dynamic> response = await Api.get(
      url: 'get-users',
      queryParameters: parameters,
    );

    List<UserModel> users = [];
    if (response['data'] != null && response['data']['data'] != null) {
      users = (response['data']['data'] as List).map((e) => UserModel.fromJson(e)).toList();
    }

    return DataOutput(total: response['data']['total'] ?? 0, modelList: users);
  }
}
