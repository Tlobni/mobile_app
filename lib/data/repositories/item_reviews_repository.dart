import 'package:tlobni/utils/api.dart';

class ItemReviewsRepository {
  // Fetch reviews for a specific item
  Future<Map> fetchItemReviews({
    required int itemId,
    int page = 1,
  }) async {
    Map response = await Api.get(
      url: Api.getItemReviewApi,
      queryParameters: {
        'service_id': itemId,
        'page': page,
      },
    );
    return response;
  }
}
