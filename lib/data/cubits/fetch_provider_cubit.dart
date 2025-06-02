import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/user/user_repository.dart';

abstract class FetchProviderState {}

class FetchProviderInitial extends FetchProviderState {}

class FetchProviderInProgress extends FetchProviderState {}

class FetchProviderSuccess extends FetchProviderState {
  final User user;

  FetchProviderSuccess({
    required this.user,
  });

  FetchProviderSuccess copyWith({
    User? user,
  }) {
    return FetchProviderSuccess(
      user: user ?? this.user,
    );
  }
}

class FetchProviderFailure extends FetchProviderState {
  final dynamic errorMessage;

  FetchProviderFailure(this.errorMessage);
}

class FetchProviderCubit extends Cubit<FetchProviderState> {
  FetchProviderCubit() : super(FetchProviderInitial());

  final UserRepository userRepository = UserRepository();

  Future fetchProvider(int id) async {
    try {
      emit(FetchProviderInProgress());

      User result = await userRepository.fetchProvider(id);
      emit(FetchProviderSuccess(user: result));
    } catch (e) {
      emit(FetchProviderFailure(e));
    }
  }
}
