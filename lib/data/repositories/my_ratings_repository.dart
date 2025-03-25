import 'package:tlobni/utils/api.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/my_review_model.dart';

class MyRatingsRepository {
  Future<DataOutput<MyReviewModel>> fetchMyRatingsAllRatings(
      {required int page}) async {
    try {
      Map<String, dynamic> parameters = {"page": page};

      Map<String, dynamic> response =
          await Api.get(url: Api.getMyReviewApi, queryParameters: parameters);

      // Ensure ratings and userRatings are not null
      int totalRatings = response["data"]["ratings"]["total"] ?? 0;

      List<MyReviewModel> userRatings =
          (response["data"]["ratings"]["data"] as List)
              .map((e) => MyReviewModel.fromJson(e))
              .toList();
      double? averageRatings;

      if (response["data"]["average_rating"] != null) {
        averageRatings = (response["data"]["average_rating"] as num).toDouble();
      }

      return DataOutput(
        total: totalRatings,
        modelList: userRatings,
        extraData: ExtraData(
          data: averageRatings, // Pass the my as extraData, which can be null
        ),
      );
    } catch (error) {
      // Handle or log the error appropriately
      rethrow;
    }
  }
}
