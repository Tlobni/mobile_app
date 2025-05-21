import 'package:tlobni/utils/api.dart';

class UserHasRatedItemRepository {
  Future<bool> getUserHasRatedItem(int? userId, int itemId) async {
    if (userId == null) return false;
    try {
      Map<String, dynamic> response = await Api.get(
        url: Api.userHasRatedItem,
        queryParameters: {
          'user_id': userId,
          'item_id': itemId,
        },
      );

      return response['data']['result'];
    } catch (e) {
      rethrow;
    }
  }
}
