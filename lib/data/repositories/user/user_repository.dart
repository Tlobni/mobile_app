import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/utils/api.dart';

class UserRepository {
  Future<DataOutput<UserModel>> fetchProviders(
      String query, ItemFilterModel? filter,
      {required int page}) async {
    Map<String, dynamic> parameters = {
      'page': page,
    };

    if (query.isNotEmpty) {
      parameters['search'] = query;
    }

    if (filter != null) {
      // Add user type from filter
      if (filter.userType != null) {
        parameters['type'] = filter.userType;
      }

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
      if (filter.city != null && filter.city!.isNotEmpty) {
        parameters['location'] = filter.city;
      }

      // Add rating range filters
      if (filter.minRating != null) {
        parameters['rating_from'] = filter.minRating;
      }
      if (filter.maxRating != null) {
        parameters['rating_to'] = filter.maxRating;
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
      users = (response['data']['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
    }

    return DataOutput(total: response['data']['total'] ?? 0, modelList: users);
  }
}
