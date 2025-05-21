import 'package:tlobni/utils/api.dart';

class UserHasRatedUserRepository {
  Future<bool> getUserHasRatedUser(int? userId, int ratedUserId) async {
    if (userId == null) return false;
    try {
      Map<String, dynamic> response = await Api.get(
        url: Api.userHasRatedUser,
        queryParameters: {
          'user_id': userId,
          'rated_user_id': ratedUserId,
        },
      );

      return response['data']['result'];
    } catch (e) {
      rethrow;
    }
  }
}
