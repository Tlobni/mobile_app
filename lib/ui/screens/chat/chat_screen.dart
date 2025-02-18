import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/add_item_review_cubit.dart';
import 'package:eClassify/data/cubits/chat/block_user_cubit.dart';
import 'package:eClassify/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:eClassify/data/cubits/chat/delete_message_cubit.dart';
import 'package:eClassify/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:eClassify/data/cubits/chat/get_seller_chat_users_cubit.dart';
import 'package:eClassify/data/cubits/chat/load_chat_messages.dart';
import 'package:eClassify/data/cubits/chat/send_message.dart';
import 'package:eClassify/data/cubits/chat/unblock_user_cubit.dart';
import 'package:eClassify/data/helper/widgets.dart';
import 'package:eClassify/data/model/chat/chat_user_model.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:eClassify/ui/screens/chat/chat_audio/widgets/chat_widget.dart';
import 'package:eClassify/ui/screens/chat/chat_audio/widgets/record_button.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/transparant_route.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_hero_animation.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/notification/chat_message_handler.dart';
import 'package:eClassify/utils/notification/notification_service.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';

int totalMessageCount = 0;

ValueNotifier<bool> showDeleteButton = ValueNotifier<bool>(false);

ValueNotifier<int> selectedMessageId = ValueNotifier<int>(-5);

class ChatScreen extends StatefulWidget {
  final String? from;
  final int itemOfferId;
  final double? itemOfferPrice;
  final double itemPrice;
  final String profilePicture;
  final String userName;
  final String itemImage;
  final String itemTitle;
  final String userId; //for which we are messaging
  final String itemId;
  final String date;
  final String? status;
  final String? buyerId;
  final int isPurchased;
  final bool alreadyReview;
  final bool? isFromBuyerList;

  const ChatScreen({
    super.key,
    required this.profilePicture,
    required this.userName,
    required this.itemImage,
    required this.itemTitle,
    required this.userId,
    required this.itemId,
    required this.date,
    this.from,
    required this.itemOfferId,
    this.status,
    required this.itemPrice,
    this.itemOfferPrice,
    this.buyerId,
    required this.isPurchased,
    required this.alreadyReview,
    this.isFromBuyerList,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _recordButtonAnimation = AnimationController(
    vsync: this,
    duration: const Duration(
      milliseconds: 500,
    ),
  );
  TextEditingController controller = TextEditingController();
  PlatformFile? messageAttachment;
  bool isFetchedFirstTime = false;
  double scrollPositionWhenLoadMore = 0;
  late Stream<PermissionStatus> notificationStream = notificationPermission();
  late StreamSubscription notificationStreamSubscription;
  bool isNotificationPermissionGranted = true;
  bool showRecordButton = true;
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  late final ScrollController _pageScrollController = ScrollController()
    ..addListener(
      () {
        if (_pageScrollController.offset >=
            _pageScrollController.position.maxScrollExtent) {
          if (context.read<LoadChatMessagesCubit>().hasMoreChat()) {
            setState(() {});
            context.read<LoadChatMessagesCubit>().loadMore();
          }
        }
      },
    );
  @override
  void initState() {
    super.initState();
    context.read<LoadChatMessagesCubit>().load(
          itemOfferId: widget.itemOfferId,
        );

    currentlyChatItemId = widget.itemId;
    currentlyChatingWith = widget.userId;
    notificationStreamSubscription =
        notificationStream.listen((PermissionStatus permissionStatus) {
      isNotificationPermissionGranted = permissionStatus.isGranted;
      if (mounted) {
        setState(() {});
      }
    });
    controller.addListener(() {
      if (controller.text.isNotEmpty) {
        showRecordButton = false;
      } else {
        showRecordButton = true;
      }
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.status == "sold out" &&
          widget.isPurchased == 1 &&
          !widget.alreadyReview) {
        ratingsAlertDialog();
      }
    });
  }

  Stream<PermissionStatus> notificationPermission() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield* Permission.notification.request().asStream();
    }
  }

  @override
  void dispose() {
    notificationStreamSubscription.cancel();
    super.dispose();
  }

  List<String> supportedImageTypes = [
    'jpeg',
    'jpg',
    'png',
    'gif',
    'webp',
    'animated_webp',
  ];

  void ratingsAlertDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,

      // Set to false if you don't want the dialog to close by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.color.secondaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Center(child: CustomText("rateSeller".translate(context))),
          content: BlocListener<AddItemReviewCubit, AddItemReviewState>(
            listener: (context, state) {
              if (state is AddItemReviewInSuccess) {
                Widgets.hideLoder(context);
                Navigator.pop(context);
                context
                    .read<GetBuyerChatListCubit>()
                    .updateAlreadyReview(int.parse(widget.itemId));
                HelperUtils.showSnackBarMessage(context, state.responseMessage);
              }
              if (state is AddItemReviewFailure) {
                Widgets.hideLoder(context);
                Navigator.pop(context);
                HelperUtils.showSnackBarMessage(
                    context, state.error.toString());
              }
              if (state is AddItemReviewInProgress) {
                Widgets.showLoader(context);
              }
            },
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        'rateYourExperience'.translate(context),
                        color: context.color.textLightColor,
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          5,
                          (index) => InkWell(
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 30,
                            ),
                            onTap: () {
                              setStater(() {
                                _rating = index + 1;
                              });
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _feedbackController,
                        decoration: InputDecoration(
                          hintText: 'shareYourExperience'.translate(context),
                          hintStyle:
                              TextStyle(color: context.color.textLightColor),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide:
                                BorderSide(color: context.color.territoryColor),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(
                              color: context.color.textLightColor
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          UiUtils.buildButton(context, onPressed: () {
                            _feedbackController.clear();
                            _rating = 0;
                            Navigator.of(context).pop();
                          },
                              buttonTitle: "cancelBtnLbl".translate(context),
                              radius: 8,
                              fontSize: 12,
                              width: context.screenWidth / 4,
                              textColor: context.color.textDefaultColor,
                              buttonColor: context.color.backgroundColor,
                              showElevation: false,
                              height: 39),
                          UiUtils.buildButton(context, showElevation: false,
                              onPressed: () {
                            context.read<AddItemReviewCubit>().addItemReview(
                                itemId: int.parse(widget.itemId),
                                rating: _rating,
                                review: _feedbackController.text.trim());
                          },
                              fontSize: 12,
                              disabled: _rating < 1,
                              disabledColor: context.color.deactivateColor,
                              buttonTitle: "submitBtnLbl".translate(context),
                              radius: 8,
                              width: context.screenWidth / 4,
                              textColor: context.color.secondaryColor,
                              buttonColor: context.color.territoryColor,
                              height: 39),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var chatBackground = "assets/chat_background/light.svg";
    var attachmentMIME = "";
    if (messageAttachment != null) {
      attachmentMIME =
          (messageAttachment?.path?.split(".").last.toLowerCase()) ?? "";
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        currentlyChatingWith = "";
        showDeleteButton.value = false;

        currentlyChatItemId = "";
        notificationStreamSubscription.cancel();
        ChatMessageHandler.flushMessages();
        return;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (messageAttachment != null) ...[
                    if (supportedImageTypes.contains(attachmentMIME)) ...[
                      Container(
                        decoration: BoxDecoration(
                            color: context.color.secondaryColor,
                            border: Border.all(
                                color: context.color.borderColor, width: 1.5)),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: GestureDetector(
                                    onTap: () {
                                      UiUtils.showFullScreenImage(context,
                                          provider: FileImage(File(
                                            messageAttachment?.path ?? "",
                                          )));
                                    },
                                    child: Image.file(
                                      File(
                                        messageAttachment?.path ?? "",
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  )),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(messageAttachment?.name ?? ""),
                                CustomText(HelperUtils.getFileSizeString(
                                  bytes: messageAttachment!.size,
                                ).toString()),
                              ],
                            )
                          ],
                        ),
                      )
                    ] else ...[
                      Container(
                        color: context.color.secondaryColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child:
                              AttachmentMessage(url: messageAttachment!.path!),
                        ),
                      ),
                    ],
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                  BottomAppBar(
                    padding: const EdgeInsetsDirectional.all(10),
                    elevation: 5,
                    color: context.color.secondaryColor,
                    child: Directionality(
                      textDirection: Directionality.of(context),
                      child: widget.status == "review" ||
                              widget.status == "rejected" ||
                              widget.status == "sold out" ||
                              widget.status == "inactive"
                          ? Container(
                              height: 40,
                              width: double.maxFinite,
                              color: context.color.secondaryColor,
                              alignment: Alignment.center,
                              child: CustomText(
                                "${"thisItemIs".translate(context)} ${widget.status}",
                                fontSize: context.font.large,
                              ))
                          : Column(
                              children: [
                                BlocProvider(
                                    create: (context) => UnblockUserCubit(),
                                    child: Builder(builder: (context) {
                                      bool isBlocked = context
                                          .read<BlockedUsersListCubit>()
                                          .isUserBlocked(
                                              int.parse(widget.userId));
                                      return BlocConsumer<BlockedUsersListCubit,
                                              BlockedUsersListState>(
                                          listener: (context, state) {
                                        if (state is BlockedUsersListSuccess) {
                                          isBlocked = context
                                              .read<BlockedUsersListCubit>()
                                              .isUserBlocked(
                                                  int.parse(widget.userId));
                                        }
                                      }, builder:
                                              (context, blockedUsersListState) {
                                        return isBlocked
                                            ? BlocListener<UnblockUserCubit,
                                                    UnblockUserState>(
                                                listener:
                                                    (context, unblockState) {
                                                  if (unblockState
                                                      is UnblockUserSuccess) {
                                                    // Remove the unblocked user from the list
                                                    context
                                                        .read<
                                                            BlockedUsersListCubit>()
                                                        .unblockUser(int.parse(
                                                            widget.userId));
                                                    HelperUtils
                                                        .showSnackBarMessage(
                                                            context,
                                                            unblockState
                                                                .message);
                                                  } else if (unblockState
                                                      is UnblockUserFail) {
                                                    HelperUtils
                                                        .showSnackBarMessage(
                                                            context,
                                                            unblockState.error
                                                                .toString());
                                                  }
                                                },
                                                child: InkWell(
                                                  child: CustomText(
                                                    "youBlockedThisContact"
                                                        .translate(context),
                                                    color: context
                                                        .color.textColorDark
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                  onTap: () async {
                                                    var unBlock = await UiUtils
                                                        .showBlurredDialoge(
                                                      context,
                                                      dialoge: BlurredDialogBox(
                                                        acceptButtonName:
                                                            "unBlockLbl"
                                                                .translate(
                                                                    context),
                                                        content: CustomText(
                                                          "${"unBlockLbl".translate(context)}\t${widget.userName}\t${"toSendMessage".translate(context)}"
                                                              .translate(
                                                                  context),
                                                        ),
                                                      ),
                                                    );
                                                    if (unBlock == true) {
                                                      Future.delayed(
                                                          Duration.zero, () {
                                                        context
                                                            .read<
                                                                UnblockUserCubit>()
                                                            .unBlockUser(
                                                              blockUserId: int
                                                                  .parse(widget
                                                                      .userId),
                                                            );
                                                      });
                                                    }
                                                  },
                                                ))
                                            : SizedBox();
                                      });
                                    })),
                                SizedBox(
                                  height: 8,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        cursorColor:
                                            context.color.territoryColor,
                                        onTap: () {
                                          showDeleteButton.value = false;
                                        },
                                        textInputAction:
                                            TextInputAction.newline,
                                        minLines: 1,
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          suffixIconColor:
                                              context.color.textLightColor,
                                          suffixIcon: IconButton(
                                            onPressed: () async {
                                              if (messageAttachment == null) {
                                                FilePickerResult?
                                                    pickedAttachment =
                                                    await FilePicker.platform
                                                        .pickFiles(
                                                  allowMultiple: false,
                                                  type: FileType.custom,
                                                  allowedExtensions: [
                                                    'jpg',
                                                    'jpeg',
                                                    'png'
                                                  ],
                                                );

                                                messageAttachment =
                                                    pickedAttachment
                                                        ?.files.first;
                                                showRecordButton = false;
                                                setState(() {});
                                              } else {
                                                messageAttachment = null;
                                                showRecordButton = true;
                                                setState(() {});
                                              }
                                            },
                                            icon: messageAttachment != null
                                                ? const Icon(Icons.close)
                                                : Transform.rotate(
                                                    angle: -3.14 / 5.0,
                                                    child: const Icon(
                                                      Icons.attachment,
                                                    ),
                                                  ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 6, horizontal: 8),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              borderSide: BorderSide(
                                                  color: context
                                                      .color.territoryColor)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              borderSide: BorderSide(
                                                  color: context
                                                      .color.territoryColor)),
                                          hintText:
                                              "writeHere".translate(context),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 9.5,
                                    ),
                                    if (showRecordButton)
                                      RecordButton(
                                        controller: _recordButtonAnimation,
                                        callback: (path) {
                                          //This is adding Chat widget in stream with BlocProvider , because we will need to do api process to store chat message to server, when it will be added to list it's initState method will be called
                                          ChatMessageHandler.add(
                                            BlocProvider(
                                              create: (context) =>
                                                  SendMessageCubit(),
                                              child: ChatMessage(
                                                  key: ValueKey(DateTime.now()
                                                      .toString()
                                                      .toString()),
                                                  message: controller.text,
                                                  senderId: int.parse(
                                                      HiveUtils.getUserId()!),
                                                  createdAt:
                                                      DateTime.now().toString(),
                                                  isSentNow: true,
                                                  audio: path,
                                                  itemOfferId:
                                                      widget.itemOfferId,
                                                  file: "",
                                                  updatedAt: DateTime.now()
                                                      .toString()),
                                            ),
                                          );
                                          totalMessageCount++;

                                          setState(() {});
                                        },
                                        isSending: false,
                                      ),
                                    if (!showRecordButton)
                                      GestureDetector(
                                        onTap: () {
                                          showDeleteButton.value = false;
                                          //if file is selected then user can send message without text
                                          if (controller.text.trim().isEmpty &&
                                              messageAttachment == null) return;
                                          //This is adding Chat widget in stream with BlocProvider , because we will need to do api process to store chat message to server, when it will be added to list it's initState method will be called

                                          ChatMessageHandler.add(
                                            BlocProvider(
                                              key: ValueKey(
                                                  DateTime.now().toString()),
                                              create: (context) =>
                                                  SendMessageCubit(),
                                              child: ChatMessage(
                                                key: ValueKey(
                                                    DateTime.now().toString()),
                                                message: controller.text,
                                                senderId: int.parse(
                                                    HiveUtils.getUserId()!),
                                                createdAt:
                                                    DateTime.now().toString(),
                                                isSentNow: true,
                                                updatedAt:
                                                    DateTime.now().toString(),
                                                audio: "",
                                                file: messageAttachment != null
                                                    ? messageAttachment?.path
                                                    : "",
                                                itemOfferId: widget.itemOfferId,
                                              ),
                                            ),
                                          );

                                          totalMessageCount++;
                                          controller.text = "";
                                          messageAttachment = null;
                                          setState(() {});
                                        },
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              context.color.territoryColor,
                                          child: Icon(
                                            Icons.send,
                                            color: context.color.buttonColor,
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            centerTitle: false,
            automaticallyImplyLeading: false,
            leading: Material(
              clipBehavior: Clip.antiAlias,
              color: Colors.transparent,
              type: MaterialType.circle,
              child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                      padding: EdgeInsetsDirectional.only(start: 15),
                      child: Directionality(
                        textDirection: Directionality.of(context),
                        child: RotatedBox(
                          quarterTurns:
                              Directionality.of(context) == TextDirection.rtl
                                  ? 2
                                  : -4,
                          child: UiUtils.getSvg(AppIcons.arrowLeft,
                              fit: BoxFit.none,
                              color: context.color.textDefaultColor),
                        ),
                      ))),
            ),
            backgroundColor: context.color.secondaryColor,
            elevation: 0,
            iconTheme: IconThemeData(color: context.color.territoryColor),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(70),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Divider(
                    color: context.color.borderColor.darken(40),
                    thickness: 1,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 25, vertical: 0),
                    color: context.color.secondaryColor,
                    height: 63,
                    child: Row(
                      children: [
                        FittedBox(
                          fit: BoxFit.none,
                          child: GestureDetector(
                            onTap: () async {
                              try {
                                Widgets.showLoader(context);

                                DataOutput<ItemModel> dataOutput =
                                    await ItemRepository().fetchItemFromItemId(
                                        int.parse(widget.itemId));

                                Future.delayed(
                                  Duration.zero,
                                  () {
                                    Widgets.hideLoder(context);
                                    Navigator.pushNamed(
                                        context, Routes.adDetailsScreen,
                                        arguments: {
                                          "model": dataOutput.modelList[0],
                                        });
                                  },
                                );
                              } catch (e) {
                                Widgets.hideLoder(context);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: SizedBox(
                                width: 47,
                                height: 47,
                                child: UiUtils.getImage(
                                  widget.itemImage,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 10),
                        // Adding horizontal space between items
                        Expanded(
                          child: Container(
                            color: context.color.secondaryColor,
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.itemTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    style: TextStyle(
                                        color: context.color.textDefaultColor,
                                        fontSize: context.font.large),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      EdgeInsetsDirectional.only(start: 15.0),
                                  child: CustomText(
                                    widget.itemPrice.currencyFormat,
                                    // Replace with your item price
                                    color: context.color.textDefaultColor,
                                    fontSize: context.font.large,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => UnblockUserCubit()),
                  BlocProvider(create: (context) => BlockUserCubit()),
                ],
                child: Builder(builder: (context) {
                  bool isBlocked = context
                      .read<BlockedUsersListCubit>()
                      .isUserBlocked(int.parse(widget.userId));
                  return BlocConsumer<BlockedUsersListCubit,
                      BlockedUsersListState>(
                    listener: (context, state) {
                      if (state is BlockedUsersListSuccess) {
                        isBlocked = context
                            .read<BlockedUsersListCubit>()
                            .isUserBlocked(int.parse(widget.userId));
                      }
                    },
                    builder: (context, blockedUsersListState) {
                      return BlocListener<BlockUserCubit, BlockUserState>(
                        listener: (context, blockState) {
                          if (blockState is BlockUserSuccess) {
                            // Add the blocked user to the list
                            context
                                .read<BlockedUsersListCubit>()
                                .addBlockedUser(
                                  BlockedUserModel(
                                      id: int.parse(widget.userId),
                                      name: widget.userName,
                                      profile: widget.profilePicture
                                      // Add other necessary user data
                                      ),
                                );
                            HelperUtils.showSnackBarMessage(
                                context, blockState.message);
                          } else if (blockState is BlockUserFail) {
                            HelperUtils.showSnackBarMessage(
                                context, blockState.error.toString());
                          }
                        },
                        child: BlocListener<UnblockUserCubit, UnblockUserState>(
                          listener: (context, unblockState) {
                            if (unblockState is UnblockUserSuccess) {
                              // Remove the unblocked user from the list
                              context
                                  .read<BlockedUsersListCubit>()
                                  .unblockUser(int.parse(widget.userId));
                              HelperUtils.showSnackBarMessage(
                                  context, unblockState.message);
                            } else if (unblockState is UnblockUserFail) {
                              HelperUtils.showSnackBarMessage(
                                  context, unblockState.error.toString());
                            }
                          },
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(end: 30.0),
                            child: Container(
                              height: 24,
                              width: 24,
                              alignment: AlignmentDirectional.center,
                              child: PopupMenuButton(
                                color: context.color.secondaryColor,
                                offset: Offset(-12, 15),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(17),
                                    bottomRight: Radius.circular(17),
                                    topLeft: Radius.circular(17),
                                    topRight: Radius.circular(0),
                                  ),
                                ),
                                child: SvgPicture.asset(
                                  AppIcons.more,
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                  colorFilter: ColorFilter.mode(
                                    context.color.textDefaultColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  if (!isBlocked)
                                    PopupMenuItem(
                                        onTap: () async {
                                          var block =
                                              await UiUtils.showBlurredDialoge(
                                            context,
                                            dialoge: BlurredDialogBox(
                                              acceptButtonName:
                                                  "blockLbl".translate(context),
                                              title:
                                                  "${"blockLbl".translate(context)}\t${widget.userName}?",
                                              content: CustomText(
                                                "blockWarning"
                                                    .translate(context),
                                              ),
                                            ),
                                          );
                                          if (block == true) {
                                            Future.delayed(Duration.zero, () {
                                              context
                                                  .read<BlockUserCubit>()
                                                  .blockUser(
                                                    blockUserId: int.parse(
                                                        widget.userId),
                                                  );
                                            });
                                          }
                                        },
                                        child: CustomText(
                                          "blockLbl".translate(context),
                                          color: context.color.textColorDark,
                                        ))
                                  else
                                    PopupMenuItem(
                                      onTap: () async {
                                        var unBlock =
                                            await UiUtils.showBlurredDialoge(
                                          context,
                                          dialoge: BlurredDialogBox(
                                            acceptButtonName:
                                                "unBlockLbl".translate(context),
                                            content: CustomText(
                                              "${"unBlockLbl".translate(context)}\t${widget.userName}\t${"toSendMessage".translate(context)}"
                                                  .translate(context),
                                            ),
                                          ),
                                        );
                                        if (unBlock == true) {
                                          Future.delayed(Duration.zero, () {
                                            context
                                                .read<UnblockUserCubit>()
                                                .unBlockUser(
                                                  blockUserId:
                                                      int.parse(widget.userId),
                                                );
                                          });
                                        }
                                      },
                                      child: CustomText(
                                        "unBlockLbl".translate(context),
                                        color: context.color.textColorDark,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              )
            ],
            title: FittedBox(
              fit: BoxFit.none,
              child: Row(
                children: [
                  widget.profilePicture == ""
                      ? CircleAvatar(
                          backgroundColor: context.color.territoryColor,
                          child: SvgPicture.asset(
                            AppIcons.profile,
                            colorFilter: ColorFilter.mode(
                                context.color.buttonColor, BlendMode.srcIn),
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              TransparantRoute(
                                barrierDismiss: true,
                                builder: (context) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      color: const Color.fromARGB(69, 0, 0, 0),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: CustomImageHeroAnimation(
                            type: CImageType.Network,
                            image: widget.profilePicture,
                            child: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                widget.profilePicture,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                      width: context.screenWidth * 0.35,
                      child: CustomText(
                        widget.userName,
                        color: context.color.textColorDark,
                        fontSize: context.font.normal,
                      )),
                ],
              ),
            ),
          ),
          body: BlocProvider(
            create: (context) => AddItemReviewCubit(),
            child: Stack(
              children: [
                //Causing lag when transitioning
                // SvgPicture.asset(
                //   chatBackground,
                //   height: MediaQuery.of(context).size.height,
                //   fit: BoxFit.cover,
                //   width: MediaQuery.of(context).size.width,
                // ),
                BlocListener<DeleteMessageCubit, DeleteMessageState>(
                  listener: (context, state) {
                    if (state is DeleteMessageSuccess) {
                      ChatMessageHandler.removeMessage(state.id);
                      showDeleteButton.value = false;
                    }
                  },
                  child: GestureDetector(
                    onTap: () {
                      showDeleteButton.value = false;
                    },
                    child: BlocConsumer<LoadChatMessagesCubit,
                        LoadChatMessagesState>(
                      listener: (context, state) {
                        if (state is LoadChatMessagesSuccess) {
                          ChatMessageHandler.loadMessages(
                              state.messages, context);
                          totalMessageCount = state.messages.length;
                          isFetchedFirstTime = true;
                          setState(() {});
                          if (widget.isFromBuyerList != null) {
                            if (widget.isFromBuyerList!) {
                              context
                                  .read<GetBuyerChatListCubit>()
                                  .removeUnreadCount(widget.itemOfferId);
                            } else {
                              context
                                  .read<GetSellerChatListCubit>()
                                  .removeUnreadCount(widget.itemOfferId);
                            }
                          }
                        }
                      },
                      builder: (context, state) {
                        return Stack(
                          children: [
                            StreamBuilder<List<Widget>>(
                                stream: ChatMessageHandler.getChatStream(),
                                builder: (context,
                                    AsyncSnapshot<List<Widget>> snapshot) {
                                  Widget? loadingMoreWidget;
                                  if (state is LoadChatMessagesSuccess) {
                                    if (state.isLoadingMore) {
                                      loadingMoreWidget = CustomText(
                                          "loading".translate(context));
                                    }
                                  }

                                  if (state is LoadChatMessagesSuccess &&
                                      state.isLoadingMore) {
                                    loadingMoreWidget = CustomText(
                                        "loading".translate(context));
                                  }

                                  if (snapshot.connectionState ==
                                          ConnectionState.active ||
                                      snapshot.connectionState ==
                                          ConnectionState.done) {
                                    if ((snapshot.data as List).isEmpty) {
                                      return offerWidget();
                                    }

                                    if (snapshot.hasData) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          loadingMoreWidget ??
                                              const SizedBox.shrink(),
                                          Expanded(
                                            child: ListView.builder(
                                              key: ValueKey(
                                                  'chat_list_${snapshot.data!.length}'),
                                              reverse: true,
                                              shrinkWrap: true,
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              controller: _pageScrollController,
                                              addAutomaticKeepAlives: true,
                                              itemCount: snapshot.data!.length,
                                              padding: const EdgeInsets.only(
                                                  bottom: 10),
                                              itemBuilder: (context, index) {
                                                dynamic chat =
                                                    snapshot.data![index];

                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (index ==
                                                        snapshot.data!.length -
                                                            1)
                                                      offerWidget(),
                                                    chat
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  }

                                  return offerWidget();
                                }),
                            if ((state is LoadChatMessagesInProgress))
                              Center(
                                child: UiUtils.progress(),
                              )
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget offerWidget() {
    if (widget.itemOfferPrice != null) {
      if (int.parse(HiveUtils.getUserId()!) == int.parse(widget.buyerId!)) {
        return Align(
          alignment: AlignmentDirectional.topEnd,
          child: Container(
              constraints: BoxConstraints(maxHeight: 70),
              margin: EdgeInsetsDirectional.only(top: 15, bottom: 15, end: 15),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(
                      color:
                          context.color.territoryColor.withValues(alpha: 0.3)),
                  color: context.color.territoryColor.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(0),
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText("yourOffer".translate(context),
                      color: context.color.textDefaultColor
                          .withValues(alpha: 0.5)),
                  CustomText(
                    (widget.itemOfferPrice ?? 0.0).currencyFormat,
                    color: context.color.textDefaultColor,
                    fontSize: context.font.larger,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              )),
        );
      } else {
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: Container(
              height: 71,
              margin:
                  EdgeInsetsDirectional.only(top: 15, bottom: 15, start: 15),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(
                      color:
                          context.color.territoryColor.withValues(alpha: 0.3)),
                  color: context.color.territoryColor.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      topLeft: Radius.circular(0),
                      bottomRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText("offerLbl".translate(context),
                      color: context.color.textDefaultColor
                          .withValues(alpha: 0.5)),
                  CustomText(
                    Constant.currencySymbol + widget.itemOfferPrice.toString(),
                    color: context.color.textDefaultColor,
                    fontSize: context.font.larger,
                    fontWeight: FontWeight.bold,
                  )
                ],
              )),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }
}
