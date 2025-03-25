// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:tlobni/data/model/chat/chat_user_model.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GetSellerChatListState {}

class GetSellerChatListInitial extends GetSellerChatListState {}

class GetSellerChatListInProgress extends GetSellerChatListState {}

class GetSellerChatListInternalProcess extends GetSellerChatListState {}

class GetSellerChatListSuccess extends GetSellerChatListState {
  final int total;
  final bool isLoadingMore;
  final bool hasError;
  final int page;
  final List<ChatUser> chatedUserList;

  GetSellerChatListSuccess({
    required this.total,
    required this.isLoadingMore,
    required this.hasError,
    required this.chatedUserList,
    required this.page,
  });

  GetSellerChatListSuccess copyWith({
    int? total,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasError,
    int? page,
    List<ChatUser>? chatedUserList,
  }) {
    return GetSellerChatListSuccess(
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      chatedUserList: chatedUserList ?? this.chatedUserList,
      page: page ?? this.page,
    );
  }
}

class GetSellerChatListFailed extends GetSellerChatListState {
  final dynamic error;

  GetSellerChatListFailed(this.error);
}

class GetSellerChatListCubit extends Cubit<GetSellerChatListState> {
  GetSellerChatListCubit() : super(GetSellerChatListInitial());
  final ChatRepository _chatRepository = ChatRepository();

  void fetch() async {
    try {
      emit(GetSellerChatListInProgress());

      DataOutput<ChatUser> result =
          await _chatRepository.fetchSellerChatList(1);

      emit(
        GetSellerChatListSuccess(
            isLoadingMore: false,
            hasError: false,
            chatedUserList: result.modelList,
            total: result.total,
            page: 1),
      );
    } catch (e) {
      emit(GetSellerChatListFailed(e));
    }
  }

  void addOrUpdateChat(ChatUser user) {
    if (state is! GetSellerChatListSuccess) return;
    final chatList = (state as GetSellerChatListSuccess).chatedUserList;

    for (final chat in chatList.indexed) {
      if (chat.$2.id == user.id) {
        final userChat = chatList.removeAt(chat.$1);

        final newChat = userChat.copyWith(
            unreadCount: (userChat.unreadCount ?? 0) + (user.unreadCount ?? 1),
            createdAt: user.createdAt,
            updatedAt: user.updatedAt);
        emit((state as GetSellerChatListSuccess)
            .copyWith(chatedUserList: [newChat, ...chatList]));
        return;
      }
    }
    chatList.insert(0, user);
    emit(
        (state as GetSellerChatListSuccess).copyWith(chatedUserList: chatList));
  }

  void removeUnreadCount(int itemOfferId) {
    if (state is! GetSellerChatListSuccess) return;
    final chatList = (state as GetSellerChatListSuccess).chatedUserList;

    for (final chat in chatList.indexed) {
      if (chat.$2.id == itemOfferId) {
        final userChat = chatList.removeAt(chat.$1);

        final newChat = userChat.copyWith(unreadCount: 0);
        emit((state as GetSellerChatListSuccess)
            .copyWith(chatedUserList: [newChat, ...chatList]));
        return;
      }
    }
  }

  Future<void> loadMore() async {
    try {
      if (state is GetSellerChatListSuccess) {
        if ((state as GetSellerChatListSuccess).isLoadingMore) {
          return;
        }
        emit((state as GetSellerChatListSuccess).copyWith(isLoadingMore: true));

        DataOutput<ChatUser> result = await _chatRepository.fetchSellerChatList(
          (state as GetSellerChatListSuccess).page + 1,
        );

        GetSellerChatListSuccess messagesSuccessState =
            (state as GetSellerChatListSuccess);

        // messagesSuccessState.await.insertAll(0, result.modelList);
        messagesSuccessState.chatedUserList.addAll(result.modelList);
        emit(GetSellerChatListSuccess(
          chatedUserList: messagesSuccessState.chatedUserList,
          page: (state as GetSellerChatListSuccess).page + 1,
          hasError: false,
          isLoadingMore: false,
          total: result.total,
        ));
      }
    } catch (e) {
      emit((state as GetSellerChatListSuccess)
          .copyWith(isLoadingMore: false, hasError: true));
    }
  }

  bool hasMoreData() {
    if (state is GetSellerChatListSuccess) {
      return (state as GetSellerChatListSuccess).chatedUserList.length <
          (state as GetSellerChatListSuccess).total;
    }

    return false;
  }
}
