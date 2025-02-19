import 'package:cached_network_image/cached_network_image.dart';
import 'package:eClassify/data/cubits/chat/delete_message_cubit.dart';
import 'package:eClassify/data/cubits/chat/load_chat_messages.dart';
import 'package:eClassify/ui/screens/chat/chat_screen.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/notification/notification_service.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class ChatTile extends StatelessWidget {
  final String profilePicture;
  final String userName;
  final String itemPicture;
  final String itemName;
  final String itemId;
  final bool isBuyerList;
  final String pendingMessageCount;
  final String id;
  final String date;
  final int itemOfferId;
  final double itemPrice;
  final double? itemAmount;
  final String? status;
  final String? buyerId;
  final int isPurchased;
  final bool alreadyReview;
  final int? unreadCount;

  const ChatTile({
    super.key,
    required this.profilePicture,
    required this.userName,
    required this.itemPicture,
    required this.itemName,
    required this.pendingMessageCount,
    required this.isBuyerList,
    required this.id,
    required this.date,
    required this.itemId,
    required this.itemOfferId,
    required this.itemPrice,
    this.status,
    this.itemAmount,
    this.buyerId,
    required this.isPurchased,
    required this.alreadyReview,
    this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, BlurredRouter(
          builder: (context) {
            currentlyChatingWith = id;
            currentlyChatItemId = itemId;
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => LoadChatMessagesCubit(),
                ),
                BlocProvider(
                  create: (context) => DeleteMessageCubit(),
                ),
              ],
              child: ChatScreen(
                profilePicture: profilePicture,
                itemTitle: itemName,
                userId: id,
                itemImage: itemPicture,
                userName: userName,
                itemId: itemId,
                date: date,
                itemOfferId: itemOfferId,
                itemPrice: itemPrice,
                itemOfferPrice: itemAmount ?? null,
                status: status,
                buyerId: buyerId,
                alreadyReview: alreadyReview,
                isPurchased: isPurchased,
                isFromBuyerList: isBuyerList,
              ),
            );
          },
        ));
      },
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.color.borderColor,
              width: 1.5,
            ),
          ),
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    const SizedBox(
                      width: 58,
                      height: 58,
                    ),
                    GestureDetector(
                      onTap: () {
                        UiUtils.showFullScreenImage(context,
                            provider: CachedNetworkImageProvider(itemPicture));
                      },
                      child: Container(
                        width: 47,
                        height: 47,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: context.color.textDefaultColor
                                    .withOpacity(0.05))),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: UiUtils.getImage(
                            itemPicture,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 8,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          UiUtils.showFullScreenImage(context,
                              provider:
                                  CachedNetworkImageProvider(profilePicture));
                        },
                        child: Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: Colors.white, width: 1)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: profilePicture == ""
                                ? CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        context.color.territoryColor,
                                    child: SvgPicture.asset(AppIcons.profile,
                                        height: 15,
                                        width: 15,
                                        colorFilter: ColorFilter.mode(
                                            context.color.buttonColor,
                                            BlendMode.srcIn)),
                                  )
                                : CircleAvatar(
                                    radius: 15,
                                    backgroundColor:
                                        context.color.territoryColor,
                                    backgroundImage:
                                        NetworkImage(profilePicture),
                                  ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        userName,
                        softWrap: true,
                        maxLines: 1,
                        color: context.color.textColorDark,
                        fontWeight: FontWeight.bold,
                      ),
                      CustomText(
                        itemName,
                        softWrap: true,
                        maxLines: 1,
                        color: context.color.textColorDark,
                      ),
                    ],
                  ),
                ),
                if (unreadCount != null && unreadCount != 0)
                  Badge(
                    backgroundColor: Colors.red,
                    label: Text(
                      '$unreadCount',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
