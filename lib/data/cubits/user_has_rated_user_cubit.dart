import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/repositories/user_has_rated_user_repository.dart';
import 'package:tlobni/utils/hive_utils.dart';

abstract class UserHasRatedUserState {}

class UserHasRatedUserInitial extends UserHasRatedUserState {}

class UserHasRatedUserInProgress extends UserHasRatedUserState {}

class UserHasRatedUserInSuccess extends UserHasRatedUserState {
  final bool userHasRatedUser;

  UserHasRatedUserInSuccess(this.userHasRatedUser);
}

class UserHasRatedUserFailure extends UserHasRatedUserState {
  final dynamic error;

  UserHasRatedUserFailure(this.error);
}

class UserHasRatedUserCubit extends Cubit<UserHasRatedUserState> {
  UserHasRatedUserCubit() : super(UserHasRatedUserInitial());
  UserHasRatedUserRepository repository = UserHasRatedUserRepository();

  // For adding reviews to expert/business profiles
  void userHasRatedUser({required int ratedUserId}) async {
    int? userId = HiveUtils.getUserIdInt();
    emit(UserHasRatedUserInProgress());

    repository.getUserHasRatedUser(userId, ratedUserId).then((value) {
      emit(UserHasRatedUserInSuccess(value));
    }).catchError((e) {
      emit(UserHasRatedUserFailure(e.toString()));
    });
  }
}
