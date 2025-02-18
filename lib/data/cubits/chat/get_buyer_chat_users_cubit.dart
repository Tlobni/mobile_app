import 'dart:developer';

import 'package:eClassify/data/model/chat/chat_user_model.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/seller_ratings_model.dart';
import 'package:eClassify/data/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GetBuyerChatListState {}

class GetBuyerChatListInitial extends GetBuyerChatListState {}

class GetBuyerChatListInProgress extends GetBuyerChatListState {}

class GetBuyerChatListInternalProcess extends GetBuyerChatListState {}

class GetBuyerChatListSuccess extends GetBuyerChatListState {
  final int total;
  final bool isLoadingMore;
  final bool hasError;
  final int page;
  final List<ChatUser> chatedUserList;

  GetBuyerChatListSuccess({
    required this.total,
    required this.isLoadingMore,
    required this.hasError,
    required this.chatedUserList,
    required this.page,
  });

  GetBuyerChatListSuccess copyWith({
    int? total,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasError,
    int? page,
    List<ChatUser>? chatedUserList,
  }) {
    return GetBuyerChatListSuccess(
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      chatedUserList: chatedUserList ?? this.chatedUserList,
      page: page ?? this.page,
    );
  }
}

class GetBuyerChatListFailed extends GetBuyerChatListState {
  final dynamic error;

  GetBuyerChatListFailed(this.error);
}

class GetBuyerChatListCubit extends Cubit<GetBuyerChatListState> {
  GetBuyerChatListCubit() : super(GetBuyerChatListInitial());
  final ChatRepository _chatRepository = ChatRepository();

  void fetch() async {
    try {
      emit(GetBuyerChatListInProgress());

      DataOutput<ChatUser> result = await _chatRepository.fetchBuyerChatList(1);

      emit(
        GetBuyerChatListSuccess(
            isLoadingMore: false,
            hasError: false,
            chatedUserList: result.modelList,
            total: result.total,
            page: 1),
      );
    } catch (e) {
      emit(GetBuyerChatListFailed(e));
    }
  }

  void addOrUpdateChat(ChatUser user) {
    if (state is! GetBuyerChatListSuccess) return;
    final chatList = (state as GetBuyerChatListSuccess).chatedUserList;

    for (final chat in chatList.indexed) {
      if (chat.$2.id == user.id) {
        final userChat = chatList.removeAt(chat.$1);

        final newChat = userChat.copyWith(
            unreadCount: (userChat.unreadCount ?? 0) + (user.unreadCount ?? 1),
            createdAt: user.createdAt,
            updatedAt: user.updatedAt);
        emit((state as GetBuyerChatListSuccess)
            .copyWith(chatedUserList: [newChat, ...chatList]));
        return;
      }
    }
    chatList.insert(0, user);
    emit((state as GetBuyerChatListSuccess).copyWith(chatedUserList: chatList));
  }

  void removeUnreadCount(int itemOfferId) {
    if (state is! GetBuyerChatListSuccess) return;
    final chatList = (state as GetBuyerChatListSuccess).chatedUserList;

    for (final chat in chatList.indexed) {
      log('${chat.$2.id} - $itemOfferId');
      if (chat.$2.id == itemOfferId) {
        final userChat = chatList.removeAt(chat.$1);

        final newChat = userChat.copyWith(unreadCount: 0);
        emit((state as GetBuyerChatListSuccess)
            .copyWith(chatedUserList: [newChat, ...chatList]));
        return;
      }
    }
  }

  void updateAlreadyReview(int itemId) {
    //this will create new chat in chat list if there is no already
    if (state is GetBuyerChatListSuccess) {
      List<ChatUser> chatedUserList =
          (state as GetBuyerChatListSuccess).chatedUserList;
      int index =
          chatedUserList.indexWhere((element) => element.itemId == itemId);

      chatedUserList[index].item!.review = UserRatings(
        sellerId: chatedUserList[index].sellerId,
        itemId: itemId,
        buyerId: chatedUserList[index].buyerId,
      );
      if (!isClosed) {
        emit((state as GetBuyerChatListSuccess)
            .copyWith(chatedUserList: chatedUserList));
      }
    }
  }

  Future<void> loadMore() async {
    try {
      if (state is GetBuyerChatListSuccess) {
        if ((state as GetBuyerChatListSuccess).isLoadingMore) {
          return;
        }
        emit((state as GetBuyerChatListSuccess).copyWith(isLoadingMore: true));

        DataOutput<ChatUser> result = await _chatRepository.fetchBuyerChatList(
          (state as GetBuyerChatListSuccess).page + 1,
        );

        GetBuyerChatListSuccess messagesSuccessState =
            (state as GetBuyerChatListSuccess);

        // messagesSuccessState.await.insertAll(0, result.modelList);
        messagesSuccessState.chatedUserList.addAll(result.modelList);
        emit(GetBuyerChatListSuccess(
          chatedUserList: messagesSuccessState.chatedUserList,
          page: (state as GetBuyerChatListSuccess).page + 1,
          hasError: false,
          isLoadingMore: false,
          total: result.total,
        ));
      }
    } catch (e) {
      emit((state as GetBuyerChatListSuccess)
          .copyWith(isLoadingMore: false, hasError: true));
    }
  }

  bool hasMoreData() {
    if (state is GetBuyerChatListSuccess) {
      return (state as GetBuyerChatListSuccess).chatedUserList.length <
          (state as GetBuyerChatListSuccess).total;
    }

    return false;
  }

  GetBuyerChatListState? fromJson(Map<String, dynamic> json) {
    return null;
  }

  Map<String, dynamic>? toJson(GetBuyerChatListState state) {
    return null;
  }

  ChatUser? getOfferForItem(int itemId) {
    if (state is GetBuyerChatListSuccess) {
      List<ChatUser> offerList =
          (state as GetBuyerChatListSuccess).chatedUserList;

      int matchingOffer = offerList.indexWhere(
        (offer) => offer.itemId == itemId,
      );
      if (matchingOffer != -1) {
        return (state as GetBuyerChatListSuccess).chatedUserList[matchingOffer];
      } else {
        return null;
      }
    }
    return null; // Return null if state is not GetBuyerChatListSuccess
  }

  void resetState() {
    emit(GetBuyerChatListInProgress());
  }
}
