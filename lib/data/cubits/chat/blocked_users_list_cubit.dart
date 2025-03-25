// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:tlobni/data/model/chat/chat_user_model.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlockedUsersListState {}

class BlockedUsersListInitial extends BlockedUsersListState {}

class BlockedUsersListInProgress extends BlockedUsersListState {}

class BlockedUsersListSuccess extends BlockedUsersListState {
  final List<BlockedUserModel> data;

  BlockedUsersListSuccess({
    required this.data,
  });

  BlockedUsersListSuccess copyWith({
    List<BlockedUserModel>? data,
  }) {
    return BlockedUsersListSuccess(data: data ?? this.data);
  }
}

class BlockedUsersListFail extends BlockedUsersListState {
  dynamic error;

  BlockedUsersListFail({
    required this.error,
  });
}

class BlockedUsersListCubit extends Cubit<BlockedUsersListState> {
  BlockedUsersListCubit() : super(BlockedUsersListInitial());

  final ChatRepository _chatRepository = ChatRepository();

  void blockedUsersList() async {
    try {
      emit(BlockedUsersListInProgress());
      DataOutput<BlockedUserModel> result =
          await _chatRepository.blockedUsersListApi();

      emit(BlockedUsersListSuccess(data: result.modelList));
    } catch (e) {
      emit(BlockedUsersListFail(error: e.toString()));
    }
  }

  bool isUserBlocked(int userId) {
    if (state is BlockedUsersListSuccess) {
      List<BlockedUserModel> list = (state as BlockedUsersListSuccess).data;

      return list.any((user) => user.id == userId);
    }
    return false;
  }

  void addBlockedUser(BlockedUserModel user) {
    //this will create new chat in chat list if there is no already
    if (state is BlockedUsersListSuccess) {
      List<BlockedUserModel> list = (state as BlockedUsersListSuccess).data;
      bool contains = list.any(
        (element) => element.id == user.id,
      );
      if (contains == false) {
        list.insert(0, user);
        emit((state as BlockedUsersListSuccess).copyWith(data: list));
      }
    }
  }

  void unblockUser(int userId) {
    if (state is BlockedUsersListSuccess) {
      List<BlockedUserModel> list = (state as BlockedUsersListSuccess).data;
      list.removeWhere((user) => user.id == userId);
      emit((state as BlockedUsersListSuccess).copyWith(data: list));
    }
  }

  void resetState() {
    emit(BlockedUsersListInProgress());
  }

  BlockedUsersListState? fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
    return null;
  }

  Map<String, dynamic>? toJson(BlockedUsersListState state) {
    // TODO: implement toJson
    return null;
  }
}
