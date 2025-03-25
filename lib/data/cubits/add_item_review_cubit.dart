import 'package:tlobni/data/repositories/add_item_review_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AddItemReviewState {}

class AddItemReviewInitial extends AddItemReviewState {}

class AddItemReviewInProgress extends AddItemReviewState {}

class AddItemReviewInSuccess extends AddItemReviewState {
  final String responseMessage;

  AddItemReviewInSuccess(this.responseMessage);
}

class AddItemReviewFailure extends AddItemReviewState {
  final dynamic error;

  AddItemReviewFailure(this.error);
}

class AddItemReviewCubit extends Cubit<AddItemReviewState> {
  AddItemReviewCubit() : super(AddItemReviewInitial());
  AddItemReviewRepository repository = AddItemReviewRepository();

  void addItemReview(
      {required int itemId,
      required int rating,
      required String review}) async {
    emit(AddItemReviewInProgress());

    repository
        .addItemReview(itemId: itemId, rating: rating, review: review)
        .then((value) {
      emit(AddItemReviewInSuccess(value['message']));
    }).catchError((e) {
      emit(AddItemReviewFailure(e.toString()));
    });
  }
}
