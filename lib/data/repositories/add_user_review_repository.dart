import 'package:tlobni/utils/api.dart';

class AddUserReviewRepository {
  // For adding reviews to expert/business profiles
  Future<Map> addUserReview({
    required int userId,
    required int rating,
    required String review,
  }) async {
    Map response = await Api.post(
      url: Api
          .addUserReviewApi, // This API endpoint needs to exist on the backend
      parameter: {'user_id': userId, 'ratings': rating, 'review': review},
    );
    return response;
  }

  // For adding reviews to specific services/experiences
  Future<Map> addServiceReview({
    required int serviceId,
    required int userId, // The owner of the service
    required int rating,
    required String review,
  }) async {
    Map response = await Api.post(
      url: Api
          .addServiceReviewApi, // This API endpoint needs to exist on the backend
      parameter: {
        'service_id': serviceId,
        'user_id': userId,
        'ratings': rating,
        'review': review
      },
    );
    return response;
  }
}
