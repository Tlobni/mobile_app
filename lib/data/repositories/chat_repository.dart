import 'package:dio/dio.dart';
import 'package:tlobni/data/model/chat/chat_user_model.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/ui/screens/chat/chat_audio/widgets/chat_widget.dart';
import 'package:tlobni/utils/api.dart';
import 'package:flutter/material.dart';

class ChatRepository {
  Future<DataOutput<ChatUser>> fetchBuyerChatList(int page) async {
    Map<String, dynamic> response = await Api.get(
        url: Api.getChatListApi,
        queryParameters: {"type": "buyer", "page": page});

    List<ChatUser> modelList = (response['data']['data'] as List).map(
      (e) {
        return ChatUser.fromJson(e);
      },
    ).toList();

    return DataOutput(total: response['data']['total'], modelList: modelList);
  }

  Future<DataOutput<ChatUser>> fetchSellerChatList(int page) async {
    Map<String, dynamic> response = await Api.get(
        url: Api.getChatListApi,
        queryParameters: {"page": page, "type": "seller"});

    List<ChatUser> modelList = (response['data']["data"] as List).map(
      (e) {
        return ChatUser.fromJson(e /*, context: _setContext*/);
      },
    ).toList();

    return DataOutput(
        total: response['data']['total'] ?? 0, modelList: modelList);
  }

  Future<DataOutput<ChatMessage>> getMessagesApi(
      {required int page, required int itemOfferId}) async {
    Map<String, dynamic> response = await Api.get(
      url: Api.chatMessagesApi,
      queryParameters: {
        "item_offer_id": itemOfferId,
        "page": page,
      },
    );

    List<ChatMessage> modelList = (response['data']['data'] as List).map(
      (result) {
        int senderId = result['sender_id'];
        String? message = result['message'];
        String? file = result['file'];
        String? audio = result['audio'];
        String createdAt = result['created_at'];
        int itemOfferId = result['item_offer_id'];
        int id = result['id'];

        return ChatMessage(
          key: ValueKey(id),
          message: message ?? "",
          senderId: senderId,
          createdAt: createdAt,
          file: file!,
          audio: audio!,
          itemOfferId: itemOfferId,
          updatedAt: createdAt,
        );
      },
    ).toList();

    return DataOutput(total: response['total'] ?? 0, modelList: modelList);
  }

  Future<Map<String, dynamic>> sendMessageApi(
      {required int itemOfferId,
      required String message,
      MultipartFile? audio,
      MultipartFile? attachment}) async {
    Map<String, dynamic> parameters = {
      "item_offer_id": itemOfferId,
    };

    if (attachment != null) {
      parameters['file'] = attachment;
    }
    if (audio != null) {
      parameters['audio'] = audio;
    }

    if (message != "") {
      parameters['message'] = message;
    }

    // Logger.error(parameters, name: "CHAT PARAMS");
    Map<String, dynamic> map =
        await Api.post(url: Api.sendMessageApi, parameter: parameters);

    return map;
  }

  Future<Map<String, dynamic>> blockUserApi({required int blockUserId}) async {
    Map<String, dynamic> parameters = {
      "blocked_user_id": blockUserId,
    };

    Map<String, dynamic> map =
        await Api.post(url: Api.blockUserApi, parameter: parameters);

    return map;
  }

  Future<Map<String, dynamic>> unBlockUserApi(
      {required int blockUserId}) async {
    Map<String, dynamic> parameters = {
      "blocked_user_id": blockUserId,
    };

    Map<String, dynamic> map =
        await Api.post(url: Api.unBlockUserApi, parameter: parameters);

    return map;
  }

  Future<DataOutput<BlockedUserModel>> blockedUsersListApi() async {
    Map<String, dynamic> response =
        await Api.get(url: Api.blockedUsersListApi, queryParameters: {});

    List<BlockedUserModel> modelList = (response['data'] as List).map(
      (e) {
        return BlockedUserModel.fromJson(e);
      },
    ).toList();

    return DataOutput(modelList: modelList, total: modelList.length);
  }
}
