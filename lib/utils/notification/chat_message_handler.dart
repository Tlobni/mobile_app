import 'dart:async';

import 'package:tlobni/ui/screens/chat/chat_audio/widgets/chat_widget.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

int sentMessages = 0;

class ChatMessageHandler {
  static List<Widget> messages = [];
  static final List<Widget> _chat = [];
  static final StreamController<List<Widget>> _chatMessageStream =
      StreamController<List<Widget>>.broadcast();

  static void add(Widget chat) {
    _chat.clear();
    _chat.insert(0, chat);

    messages = [..._chat, ...messages];
    _chatMessageStream.sink.add(messages);
  }

  static void loadMessages(List<Widget> chats, BuildContext context) {
    List<Widget> messagesWithDate = [];
    String previousDate = "";
    // Get the current date and time
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    for (int i = chats.length - 1; i >= 0; i--) {
      DateTime date =
          DateTime.parse((chats[i] as ChatMessage).createdAt).toLocal();
      String formattedDate;

      if (date.isAfter(today)) {
        formattedDate = "today".translate(context);
      } else if (date.isAfter(yesterday)) {
        formattedDate = "yesterday".translate(context);
      } else {
        formattedDate = (date.toString()).formatDate();
      }

      // Add date widget if date has changed
      if (formattedDate != previousDate) {
        messagesWithDate.insert(0, messageDateChip(context, formattedDate));
        previousDate = formattedDate;
      }

      // Add message widget
      messagesWithDate.insert(0, chats[i]);
    }

    // Update the messages list and sink the new messages to the stream
    messages = messagesWithDate;
    // messages = chats; //uncomment and comment above code if problem in chat
    _chatMessageStream.sink.add(messages);
    //getChatStream();
  }

  static Widget messageDateChip(BuildContext context, String formattedDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
          child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: context.color.territoryColor.withOpacity(0.3)),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: CustomText(formattedDate),
        ),
      )),
    );
  }

  static void flushMessages() {
    messages.clear();
    _chat.clear();
  }

  static Stream<List<Widget>> getChatStream() {
    return _chatMessageStream.stream;
  }

  static void attachListener(void Function(dynamic)? onData) {
    _chatMessageStream.stream.listen(onData);
  }

  static void removeMessage(int id) {
    List<Widget> msgs = (messages);
    msgs.removeWhere((element) {
      if (element is! Padding) {
        return ((element as ChatMessage).key as ValueKey).value == id;
      }
      return false;
    });

    _chatMessageStream.sink.add(msgs);
  }

  ///This will replace message's key with server key so we will be able to delete message if we want
  static void updateMessageId(String identifier, int id) {
    try {
      List<Widget> msgs = _chat;
      for (var i = 0; i < _chat.length; i++) {
        //We will only need to change its key when it is bloc provider because we added it locally and its key was also locally so we have to replace it with server key when message send complete
        if (msgs[i] is BlocProvider) {
          ///Extracting chate message from bloc provider
          Widget? bloc = (msgs[i] as BlocProvider).child;
          ChatMessage chat = (bloc as ChatMessage);

          ///Extracting its key [which we were added locally]
          String chatKey = (chat.key as ValueKey).value;

          ///This identifier will come from ChatMessage's key when message send success.
          ///this identifier must be same as chatKey because we want exact element to change
          if (identifier == chatKey) {
            ///Converting chat class to map and replace its key and again convert it to ChatMessage class
            var map = chat.toJson();
            map['key'] = ValueKey(id);

            try {
              ChatMessage chatMessage = ChatMessage.fromJson(map);

              ///Replace it with old one
              _chat[i] = chatMessage;
            } catch (e) {}

            ///This will add chats in first and old messages in last...
            msgs = [..._chat, ...messages];
            _chatMessageStream.sink.add(msgs);
          }
        }
      }
    } catch (e) {}
  }
}
