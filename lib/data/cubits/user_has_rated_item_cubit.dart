import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/repositories/user_has_rated_item_repository.dart';
import 'package:tlobni/utils/hive_utils.dart';

abstract class UserHasRatedItemState {}

class UserHasRatedItemInitial extends UserHasRatedItemState {}

class UserHasRatedItemInProgress extends UserHasRatedItemState {}

class UserHasRatedItemInSuccess extends UserHasRatedItemState {
  final bool userHasRatedItem;

  UserHasRatedItemInSuccess(this.userHasRatedItem);
}

class UserHasRatedItemFailure extends UserHasRatedItemState {
  final dynamic error;

  UserHasRatedItemFailure(this.error);
}

class UserHasRatedItemCubit extends Cubit<UserHasRatedItemState> {
  UserHasRatedItemCubit() : super(UserHasRatedItemInitial());
  UserHasRatedItemRepository repository = UserHasRatedItemRepository();

  // For adding reviews to expert/business profiles
  void userHasRatedItem({required int itemId}) async {
    int? userId = HiveUtils.getUserIdInt();
    emit(UserHasRatedItemInProgress());

    repository.getUserHasRatedItem(userId, itemId).then((value) {
      emit(UserHasRatedItemInSuccess(value));
    }).catchError((e) {
      emit(UserHasRatedItemFailure(e.toString()));
    });
  }
}
