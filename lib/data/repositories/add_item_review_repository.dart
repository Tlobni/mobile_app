import 'package:eClassify/utils/api.dart';

class AddItemReviewRepository {
  Future<Map> addItemReview(
      {required int itemId,
      required int rating,
      required String review}) async {
    Map response = await Api.post(
      url: Api.addItemReviewApi,
      parameter: {Api.itemId: itemId, Api.ratings: rating, Api.review: review},
    );
    return response;
  }
}
