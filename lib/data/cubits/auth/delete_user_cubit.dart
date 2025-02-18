// ignore_for_file: file_names

import 'package:eClassify/data/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DeleteUserState {}

class DeleteUserInitial extends DeleteUserState {}

class DeleteUserFetchInProgress extends DeleteUserState {}

class DeleteUserFetchSuccess extends DeleteUserState {
  dynamic deleteUser;

  DeleteUserFetchSuccess({required this.deleteUser});
}

class DeleteUserFetchFailure extends DeleteUserState {
  final String errorMessage;

  DeleteUserFetchFailure(this.errorMessage);
}

class DeleteUserCubit extends Cubit<DeleteUserState> {
  DeleteUserCubit() : super(DeleteUserInitial());
  AuthRepository _deleteUserRepository = AuthRepository();

  Future<dynamic> deleteUser(
      {String? name, String? mobile, String? email, String? filePath}) async {
    try {
      emit(DeleteUserFetchInProgress());
      final result = await _deleteUserRepository.deleteUser();
      emit(DeleteUserFetchSuccess(deleteUser: result));
      return result;
    } catch (e) {
      emit(DeleteUserFetchFailure(e.toString()));
    }
  }
}
