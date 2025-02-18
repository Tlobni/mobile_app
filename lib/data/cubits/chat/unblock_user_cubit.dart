// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:eClassify/data/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnblockUserState {}

class UnblockUserInitial extends UnblockUserState {}

class UnblockUserInProgress extends UnblockUserState {}

class UnblockUserSuccess extends UnblockUserState {
  final dynamic message;

  UnblockUserSuccess({
    required this.message,
  });
}

class UnblockUserFail extends UnblockUserState {
  dynamic error;

  UnblockUserFail({
    required this.error,
  });
}

class UnblockUserCubit extends Cubit<UnblockUserState> {
  UnblockUserCubit() : super(UnblockUserInitial());

  final ChatRepository _chatRepository = ChatRepository();

  void unBlockUser({required int blockUserId}) async {
    try {
      emit(UnblockUserInProgress());

      var result =
          await _chatRepository.unBlockUserApi(blockUserId: blockUserId);

      emit(UnblockUserSuccess(message: result['message']));
    } catch (e) {
      emit(UnblockUserFail(error: e.toString()));
    }
  }
}
