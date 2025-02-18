import 'package:eClassify/utils/api.dart';

class AddMyItemReportReviewRepository {
  Future<Map> addMyItemReportReview(
      {required int sellerReviewId, required String reportReason}) async {
    Map response = await Api.post(
      url: Api.addReviewReportApi,
      parameter: {
        Api.sellerReviewId: sellerReviewId,
        Api.reportReason: reportReason
      },
    );
    return response;
  }
}
