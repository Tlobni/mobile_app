// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:io';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/data/cubits/chat/send_message.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/ui/screens/chat/chat_screen.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

part "parts/attachment.part.dart";
part "parts/linkpreview.part.dart";
part "parts/recordmsg.part.dart";

////Please don't make changes without sufficent knowledege in this file. otherwise you will be responsable for it
///
//This will store and ensure that msg is already sent so we don't have to send it again
Set sentMessages = {};

class ChatMessage extends StatefulWidget {
  final int? id;
  final int senderId;
  final int itemOfferId;
  final String? message;
  final String? file;
  final String? audio;
  final String createdAt;
  final String updatedAt;
  final String? messageType;
  final bool? isSentNow;

  const ChatMessage(
      {super.key,
      this.id,
      required this.senderId,
      required this.itemOfferId,
      this.message,
      this.file,
      this.audio,
      required this.createdAt,
      required this.updatedAt,
      this.messageType,
      this.isSentNow});

  Map toJson() {
    Map data = {};

    data['key'] = key;
    data['id'] = this.id;
    data['sender_id'] = this.senderId;
    data['item_offer_id'] = this.itemOfferId;
    data['message'] = this.message;
    data['file'] = this.file;
    data['audio'] = this.audio;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['is_sent_now'] = this.isSentNow;
    data['message_type'] = this.messageType;
    return data;
  }

  factory ChatMessage.fromJson(Map json) {
    var chat = ChatMessage(
        key: json['key'],
        id: json['id'],
        senderId: json['sender_id'],
        itemOfferId: json['item_offer_id'],
        message: json['message'],
        file: json['file'],
        audio: json['audio'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        isSentNow: json['is_sent_now'],
        messageType: json['message_type']);
    return chat;
  }

  @override
  State<ChatMessage> createState() => ChatMessageState();
}

class ChatMessageState extends State<ChatMessage>
    with AutomaticKeepAliveClientMixin {
  bool isChatSent = false;
  bool selectedMessage = false;
  static bool isMounted = false;
  String? link;
  final ValueNotifier _linkAddNotifier = ValueNotifier("");

  @override
  void initState() {
    if (widget.senderId.toString() == HiveUtils.getUserId() &&
        (widget.isSentNow == true) &&
        isChatSent == false) {
      if (!sentMessages.contains(widget.key)) {
        context.read<SendMessageCubit>().send(
              attachment: widget.file,
              message: widget.message!,
              itemOfferId: widget.itemOfferId,
              audio: widget.audio,
            );
      }
      sentMessages.add(widget.key);

      isMounted = true;
    }

    super.initState();
  }

  String _emptyTextIfAttachmentHasNoCustomText() {
    if (widget.file != "") {
      if (widget.message == "[File]") {
        return "";
      } else {
        return widget.message!;
      }
    } else if (widget.message == null) {
      return "";
    } else {
      return widget.message!;
    }
  }

  bool _isLink(String input) {
    ///This will check if text contains link
    final matcher = RegExp(
        r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)");
    return matcher.hasMatch(input);
  }

  List _replaceLink() {
    //This function will make part of text where link starts. we put invisible charector so we can split it with it
    final linkPattern = RegExp(
        r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)");

    ///This is invisible charector [You can replace it with any special charector which generally nobody use]
    const String substringIdentifier = "‎";

    ///This will find and add invisible charector in prefix and suffix
    String splitMapJoin = _emptyTextIfAttachmentHasNoCustomText().splitMapJoin(
      linkPattern,
      onMatch: (match) {
        return substringIdentifier + match.group(0)! + substringIdentifier;
      },
      onNonMatch: (match) {
        return match;
      },
    );
    //finally we split it with invisible charector so it will become list
    return splitMapJoin.split(substringIdentifier);
  }

  List<String> _matchAstric(String data) {
    var pattern = RegExp(r"\*(.*?)\*");

    String mapJoin = data.splitMapJoin(
      pattern,
      onMatch: (p0) {
        return "‎${p0.group(0)!}‎";
      },
      onNonMatch: (p0) {
        return p0;
      },
    );

    return mapJoin.split("‎");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    bool isDark =
        context.watch<AppThemeCubit>().state.appTheme == AppTheme.dark;

    return GestureDetector(
      onLongPress: () {
        selectedMessageId.value = (widget.key as ValueKey).value;
        showDeleteButton.value = true;
      },
      onTap: () {
        selectedMessage = false;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Container(
          alignment: widget.senderId.toString() == HiveUtils.getUserId()
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsetsDirectional.only(
            // top: MediaQuery.of(context).size.height * 0.007,
            end: widget.senderId.toString() == HiveUtils.getUserId() ? 20 : 0,
            start: widget.senderId.toString() == HiveUtils.getUserId() ? 0 : 20,
          ),
          child: Column(
            crossAxisAlignment:
                widget.senderId.toString() == HiveUtils.getUserId()
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
            children: [
              Container(
                constraints:
                    BoxConstraints(maxWidth: context.screenWidth * 0.74),
                decoration: BoxDecoration(
                    color: selectedMessage == true
                        ? (widget.senderId.toString() == HiveUtils.getUserId()
                            ? context.color.territoryColor.darken(45)
                            : context.color.secondaryColor.darken(45))
                        : (widget.senderId.toString() == HiveUtils.getUserId()
                            ? context.color.territoryColor.withOpacity(0.3)
                            : context.color.secondaryColor),
                    borderRadius: BorderRadius.circular(8)),
                child: Wrap(
                  runAlignment: WrapAlignment.end,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        child: widget.audio != ""
                            ? RecordMessage(
                                url: widget.audio ?? "",
                                isSentByMe: widget.senderId.toString() ==
                                    HiveUtils.getUserId(),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.file != "")
                                    AttachmentMessage(url: widget.file!),

                                  //This is preview builder for image
                                  ValueListenableBuilder(
                                      valueListenable: _linkAddNotifier,
                                      builder: (context, dynamic value, c) {
                                        if (value == null) {
                                          return const SizedBox.shrink();
                                        }

                                        return FutureBuilder(
                                          future: AnyLinkPreview.getMetadata(
                                              link: value),
                                          builder: (context,
                                              AsyncSnapshot snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.done) {
                                              if (snapshot.data == null) {
                                                return const SizedBox.shrink();
                                              }
                                              return LinkPreviw(
                                                snapshot: snapshot,
                                                link: value,
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        );
                                      }),
                                  SelectableText.rich(
                                    TextSpan(
                                      style: TextStyle(
                                          color: (isDark &&
                                                  widget.senderId.toString() !=
                                                      HiveUtils.getUserId())
                                              ? context.color.buttonColor
                                              : context.color.textDefaultColor),
                                      children: _replaceLink().map((data) {
                                        //This will add link to msg
                                        if (_isLink(data)) {
                                          //This will notify priview object that it has link
                                          _linkAddNotifier.value = data;
                                          _linkAddNotifier.notifyListeners();

                                          return TextSpan(
                                              text: data,
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () async {
                                                  await launchUrl(
                                                      Uri.parse(data));
                                                },
                                              style: TextStyle(
                                                  decoration:
                                                      TextDecoration.underline,
                                                  color: Colors.blue[800]));
                                        }
                                        //This will make text bold
                                        return TextSpan(
                                          text: "",
                                          children:
                                              _matchAstric(data).map((text) {
                                            if (text
                                                    .toString()
                                                    .startsWith("*") &&
                                                text.toString().endsWith("*")) {
                                              return TextSpan(
                                                  text:
                                                      text.replaceAll("*", ""),
                                                  style: TextStyle(
                                                      color: (isDark &&
                                                              widget.senderId
                                                                      .toString() !=
                                                                  HiveUtils
                                                                      .getUserId())
                                                          ? context
                                                              .color.buttonColor
                                                          : context.color
                                                              .textDefaultColor,
                                                      fontWeight:
                                                          FontWeight.w800));
                                            }

                                            return TextSpan(
                                                text: text,
                                                style: TextStyle(
                                                    color: (isDark &&
                                                            widget.senderId
                                                                    .toString() !=
                                                                HiveUtils
                                                                    .getUserId())
                                                        ? context
                                                            .color.buttonColor
                                                        : context.color
                                                            .textDefaultColor));
                                          }).toList(),
                                          style: TextStyle(
                                              color: widget.senderId
                                                          .toString() ==
                                                      HiveUtils.getUserId()
                                                  ? context.color.secondaryColor
                                                  : context
                                                      .color.textColorDark),
                                        );
                                      }).toList(),
                                    ),
                                    style: TextStyle(
                                        color: (isDark &&
                                                widget.senderId.toString() !=
                                                    HiveUtils.getUserId())
                                            ? context.color.buttonColor
                                            : context.color.textDefaultColor),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (widget.senderId.toString() != HiveUtils.getUserId() &&
                        (widget.isSentNow != null
                            ? widget.isSentNow!
                            : widget.createdAt ==
                                DateTime.now().toString())) ...[
                      BlocConsumer<SendMessageCubit, SendMessageState>(
                        listener: (context, state) {
                          if (state is SendMessageSuccess) {
                            isChatSent = true;

                            WidgetsBinding.instance
                                .addPostFrameCallback((timeStamp) {
                              if (mounted) setState(() {});
                            });
                          }
                          if (state is SendMessageFailed) {
                            HelperUtils.showSnackBarMessage(
                                context, state.error.toString());
                          }
                        },
                        builder: (context, state) {
                          if (state is SendMessageInProgress) {
                            return Padding(
                              padding: EdgeInsetsDirectional.only(
                                  end: 5.0, bottom: 2),
                              child: Icon(
                                Icons.watch_later_outlined,
                                size: context.font.smaller,
                                color: context.color.textLightColor,
                              ),
                            );
                          }

                          if (state is SendMessageFailed) {
                            return Padding(
                              padding: EdgeInsetsDirectional.only(
                                  end: 5.0, bottom: 2),
                              child: Icon(
                                Icons.error,
                                size: context.font.smaller,
                                color: context.color.primaryColor,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(end: 3.0),
                child: CustomText(
                  (DateTime.parse(widget.createdAt))
                      .toLocal()
                      .toIso8601String()
                      .toString()
                      .formatDate(
                        format: "hh:mm aa",
                      ),
                  color: widget.senderId.toString() != HiveUtils.getUserId()
                      ? context.color.textLightColor
                      : context.color.textLightColor,
                  fontSize: context.font.smaller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
