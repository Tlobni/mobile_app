import 'package:tlobni/data/repositories/add_user_review_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AddUserReviewState {}

class AddUserReviewInitial extends AddUserReviewState {}

class AddUserReviewInProgress extends AddUserReviewState {}

class AddUserReviewInSuccess extends AddUserReviewState {
  final String responseMessage;

  AddUserReviewInSuccess(this.responseMessage);
}

class AddUserReviewFailure extends AddUserReviewState {
  final dynamic error;

  AddUserReviewFailure(this.error);
}

class AddUserReviewCubit extends Cubit<AddUserReviewState> {
  AddUserReviewCubit() : super(AddUserReviewInitial());
  AddUserReviewRepository repository = AddUserReviewRepository();

  // For adding reviews to expert/business profiles
  void addUserReview({
    required int userId,
    required int rating,
    required String review,
  }) async {
    emit(AddUserReviewInProgress());

    repository
        .addUserReview(userId: userId, rating: rating, review: review)
        .then((value) {
      emit(AddUserReviewInSuccess(value['message']));
    }).catchError((e) {
      emit(AddUserReviewFailure(e.toString()));
    });
  }

  // For adding reviews to service/experience
  void addServiceReview({
    required int serviceId,
    required int userId,
    required int rating,
    required String review,
  }) async {
    emit(AddUserReviewInProgress());

    repository
        .addServiceReview(
      serviceId: serviceId,
      userId: userId,
      rating: rating,
      review: review,
    )
        .then((value) {
      emit(AddUserReviewInSuccess(value['message']));
    }).catchError((e) {
      emit(AddUserReviewFailure(e.toString()));
    });
  }
}
