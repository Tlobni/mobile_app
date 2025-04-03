import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:tlobni/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:tlobni/data/cubits/chat/get_seller_chat_users_cubit.dart';
import 'package:tlobni/data/model/chat/chat_user_model.dart';
import 'package:tlobni/ui/screens/chat/chatTile.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return const ChatListScreen();
      },
    );
  }

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  ScrollController chatScreenController = ScrollController();

  @override
  void initState() {
    if (HiveUtils.isUserAuthenticated()) {
      context.read<GetBuyerChatListCubit>().fetch();
      context.read<GetSellerChatListCubit>().fetch();
      context.read<BlockedUsersListCubit>().blockedUsersList();
      chatScreenController.addListener(() {
        if (chatScreenController.isEndReached()) {
          if (context.read<GetBuyerChatListCubit>().hasMoreData()) {
            context.read<GetBuyerChatListCubit>().loadMore();
          }
          if (context.read<GetSellerChatListCubit>().hasMoreData()) {
            context.read<GetSellerChatListCubit>().loadMore();
          }
        }
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: UiUtils.buildAppBar(
          context,
          title: "message".translate(context),
          actions: [
            InkWell(
              child: UiUtils.getSvg(AppIcons.blockedUserIcon,
                  color: context.color.textDefaultColor),
              onTap: () {
                Navigator.pushNamed(context, Routes.blockedUserListScreen);
              },
            )
          ],
        ),
        body: combinedChatListData(),
      ),
    );
  }

  Widget combinedChatListData() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<GetBuyerChatListCubit>().fetch();
        context.read<GetSellerChatListCubit>().fetch();
      },
      color: context.color.territoryColor,
      child: BlocBuilder<GetBuyerChatListCubit, GetBuyerChatListState>(
        builder: (context, buyerState) {
          return BlocBuilder<GetSellerChatListCubit, GetSellerChatListState>(
            builder: (context, sellerState) {
              // Handle loading states
              if (buyerState is GetBuyerChatListInProgress ||
                  sellerState is GetSellerChatListInProgress) {
                return buildChatListLoadingShimmer();
              }

              // Handle error states
              if ((buyerState is GetBuyerChatListFailed &&
                  sellerState is GetSellerChatListFailed)) {
                if ((buyerState.error is ApiException &&
                        buyerState.error.errorMessage == "no-internet") ||
                    (sellerState.error is ApiException &&
                        sellerState.error.errorMessage == "no-internet")) {
                  return NoInternet(
                    onRetry: () {
                      context.read<GetBuyerChatListCubit>().fetch();
                      context.read<GetSellerChatListCubit>().fetch();
                    },
                  );
                }
                return const NoChatFound();
              }

              // Extract chat lists
              List<ChatUser> buyerChats = [];
              if (buyerState is GetBuyerChatListSuccess) {
                buyerChats = buyerState.chatedUserList;
              }

              List<ChatUser> sellerChats = [];
              if (sellerState is GetSellerChatListSuccess) {
                sellerChats = sellerState.chatedUserList;
              }

              // Combine the lists
              List<Map<String, dynamic>> combinedChats = [];

              // Add buyer chats
              for (var chat in buyerChats) {
                combinedChats.add({
                  'chat': chat,
                  'isBuyerList': true,
                  'date': chat.createdAt,
                });
              }

              // Add seller chats
              for (var chat in sellerChats) {
                combinedChats.add({
                  'chat': chat,
                  'isBuyerList': false,
                  'date': chat.createdAt,
                });
              }

              // Sort by date (most recent first)
              combinedChats.sort((a, b) {
                DateTime dateA = DateTime.parse(a['date'] ?? '');
                DateTime dateB = DateTime.parse(b['date'] ?? '');
                return dateB.compareTo(dateA);
              });

              if (combinedChats.isEmpty) {
                return NoChatFound();
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: chatScreenController,
                      shrinkWrap: true,
                      itemCount: combinedChats.length,
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 8, vertical: 4),
                      itemBuilder: (context, index) {
                        final chatData = combinedChats[index];
                        final ChatUser chatUser = chatData['chat'];
                        final bool isBuyerList = chatData['isBuyerList'];

                        if (isBuyerList) {
                          // Buyer chat tile
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ChatTile(
                              id: chatUser.sellerId.toString(),
                              itemId: chatUser.itemId.toString(),
                              isBuyerList: true,
                              profilePicture: chatUser.seller != null &&
                                      chatUser.seller!.profile != null
                                  ? chatUser.seller!.profile!
                                  : "",
                              userName: chatUser.seller != null &&
                                      chatUser.seller!.name != null
                                  ? chatUser.seller!.name!
                                  : "",
                              itemPicture: chatUser.item != null &&
                                      chatUser.item!.image != null
                                  ? chatUser.item!.image!
                                  : "",
                              itemName: chatUser.item != null &&
                                      chatUser.item!.name != null
                                  ? chatUser.item!.name!
                                  : "",
                              pendingMessageCount: "5",
                              date: chatUser.createdAt!,
                              itemOfferId: chatUser.id!,
                              itemPrice: chatUser.item != null &&
                                      chatUser.item!.price != null
                                  ? chatUser.item!.price!
                                  : 0.0,
                              itemAmount: chatUser.amount ?? null,
                              status: chatUser.item != null &&
                                      chatUser.item!.status != null
                                  ? chatUser.item!.status!
                                  : null,
                              buyerId: chatUser.buyerId.toString(),
                              isPurchased: chatUser.item!.isPurchased ?? 0,
                              alreadyReview:
                                  chatUser.item!.review == null ? false : true,
                              unreadCount: chatUser.unreadCount,
                            ),
                          );
                        } else {
                          // Seller chat tile
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ChatTile(
                              id: chatUser.buyerId.toString(),
                              itemId: chatUser.itemId.toString(),
                              isBuyerList: false,
                              profilePicture: chatUser.buyer?.profile ?? "",
                              userName: chatUser.buyer?.name ?? "",
                              itemPicture: chatUser.item != null &&
                                      chatUser.item!.image != null
                                  ? chatUser.item!.image!
                                  : "",
                              itemName: chatUser.item != null &&
                                      chatUser.item!.name != null
                                  ? chatUser.item!.name!
                                  : "",
                              pendingMessageCount: "5",
                              date: chatUser.createdAt ?? '',
                              itemOfferId: chatUser.id!,
                              itemPrice: chatUser.item != null &&
                                      chatUser.item!.price != null
                                  ? chatUser.item!.price!
                                  : 0,
                              itemAmount: chatUser.amount ?? null,
                              status: chatUser.item != null &&
                                      chatUser.item!.status != null
                                  ? chatUser.item!.status!
                                  : null,
                              buyerId: chatUser.buyerId.toString(),
                              isPurchased: chatUser.item?.isPurchased ?? 0,
                              alreadyReview:
                                  chatUser.item!.review == null ? false : true,
                              unreadCount: chatUser.unreadCount,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  if ((buyerState is GetBuyerChatListSuccess &&
                          buyerState.isLoadingMore) ||
                      (sellerState is GetSellerChatListSuccess &&
                          sellerState.isLoadingMore))
                    UiUtils.progress()
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget buildChatListLoadingShimmer() {
    return ListView.builder(
        itemCount: 10,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(top: 9.0),
            child: SizedBox(
              height: 74,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
                      highlightColor:
                          Theme.of(context).colorScheme.shimmerHighlightColor,
                      child: Stack(
                        children: [
                          const SizedBox(
                            width: 58,
                            height: 58,
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 42,
                              height: 42,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                  color: Colors.grey,
                                  border: Border.all(
                                      width: 1.5, color: Colors.white),
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          PositionedDirectional(
                            end: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2)),
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: context.color.territoryColor,
                                  // backgroundImage: NetworkImage(profilePicture),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomShimmer(
                          height: 10,
                          borderRadius: 5,
                          width: context.screenWidth * 0.53,
                        ),
                        CustomShimmer(
                          height: 10,
                          borderRadius: 5,
                          width: context.screenWidth * 0.3,
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}
