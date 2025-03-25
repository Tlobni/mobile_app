import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/seller_ratings_model.dart';
import 'package:tlobni/utils/api.dart';

class SellerRatingsRepository {
  Future<DataOutput<UserRatings>> fetchSellerRatingsAllRatings(
      {required int sellerId, required int page}) async {
    try {
      Map<String, dynamic> parameters = {"user_id": sellerId, "page": page};

      Map<String, dynamic> response =
          await Api.get(url: Api.getUserReviewApi, queryParameters: parameters);

      // Print response for debugging
      print("User review API response: $response");

      // Extract the reviews data and average rating
      final reviewsData = response["data"]["reviews"] ?? {};
      final averageRating = response["data"]["average_rating"] ?? 0.0;

      // Create a seller object with the average rating
      Seller seller = Seller(
        id: sellerId,
        averageRating: averageRating is int
            ? averageRating.toDouble()
            : (averageRating is double ? averageRating : 0.0),
      );

      // Extract the review items
      final List<dynamic> reviewItems = reviewsData["data"] ?? [];

      // Convert to UserRatings objects
      List<UserRatings> userRatings = reviewItems.map((item) {
        return UserRatings.fromJson(item);
      }).toList();

      // Get the total count from the response
      final int totalRatings = reviewsData["total"] ?? 0;

      return DataOutput(
        total: totalRatings,
        modelList: userRatings,
        extraData: ExtraData(
          data: seller,
        ),
      );
    } catch (error) {
      print("Error fetching user reviews: $error");
      // Handle or log the error appropriately
      rethrow;
    }
  }
}
