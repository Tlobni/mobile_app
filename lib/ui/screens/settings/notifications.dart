import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/cubits/fetch_notifications_cubit.dart';
import 'package:tlobni/data/helper/custom_exception.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/notification_data.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

late NotificationData selectedNotification;

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  NotificationsState createState() => NotificationsState();

  static Route route(RouteSettings routeSettings) {
    return BlurredRouter(
      builder: (_) => const Notifications(),
    );
  }
}

class NotificationsState extends State<Notifications> {
  late final ScrollController _pageScrollController = ScrollController();

  List<ItemModel> itemData = [];

  @override
  void initState() {
    super.initState();
    AdHelper.loadInterstitialAd();
    context.read<FetchNotificationsCubit>().fetchNotifications();
    _pageScrollController.addListener(_pageScroll);

    // Mark notifications as read when screen is opened
    if (HiveUtils.isUserAuthenticated()) {
      _markNotificationsAsRead();
    }
  }

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchNotificationsCubit>().hasMoreData()) {
        context.read<FetchNotificationsCubit>().fetchNotificationsMore();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AdHelper.showInterstitialAd();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        title: "notifications".translate(context),
        showBackButton: true,
      ),
      body: BlocBuilder<FetchNotificationsCubit, FetchNotificationsState>(builder: (context, state) {
        if (state is FetchNotificationsInProgress) {
          return buildNotificationShimmer();
        }
        if (state is FetchNotificationsFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage.error == "no-internet") {
              return NoInternet(
                onRetry: () {
                  context.read<FetchNotificationsCubit>().fetchNotifications();
                },
              );
            }
          }

          return const SomethingWentWrong();
        }

        if (state is FetchNotificationsSuccess) {
          if (state.notificationdata.isEmpty) {
            return NoDataFound(
              onTap: () {
                context.read<FetchNotificationsCubit>().fetchNotifications();
              },
            );
          }

          return buildNotificationListWidget(state);
        }

        return const SizedBox.square();
      }),
    );
  }

  Widget buildNotificationShimmer() {
    return ListView.separated(
        padding: const EdgeInsets.all(10),
        separatorBuilder: (context, index) => const SizedBox(
              height: 10,
            ),
        itemCount: 20,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return SizedBox(
            height: 55,
            child: Row(
              children: <Widget>[
                const CustomShimmer(
                  width: 50,
                  height: 50,
                  borderRadius: 11,
                ),
                const SizedBox(
                  width: 5,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CustomShimmer(
                      height: 7,
                      width: 200,
                    ),
                    const SizedBox(height: 5),
                    CustomShimmer(
                      height: 7,
                      width: 100,
                    ),
                    const SizedBox(height: 5),
                    CustomShimmer(
                      height: 7,
                      width: 150,
                    )
                  ],
                )
              ],
            ),
          );
        });
  }

  Column buildNotificationListWidget(FetchNotificationsSuccess state) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
              controller: _pageScrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(10),
              separatorBuilder: (context, index) => const SizedBox(height: 35),
              itemCount: state.notificationdata.length,
              itemBuilder: (context, index) {
                NotificationData notificationData = state.notificationdata[index];

                // For providers, visually mark provider-specific notifications as read
                // when they view them
                if (HiveUtils.getUserType() == "Expert" || HiveUtils.getUserType() == "Business") {
                  if (notificationData.isProviderNotification() && !notificationData.isRead) {
                    notificationData.markAsRead();
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: DescriptionText(notificationData.title ?? '', maxLines: 1)),
                        DescriptionText(UiUtils.dateToAgoString(notificationData.createdAt), fontSize: 14),
                      ],
                    ),
                    const SizedBox(height: 5),
                    DescriptionText(notificationData.message ?? '', fontSize: 14),
                  ],
                );
              }),
        ),
        if (state.isLoadingMore) UiUtils.progress()
      ],
    );
  }

  Future<List<ItemModel>> getItemById() async {
    Map<String, dynamic> body = {
      // ApiParams.id: itemsId,//String itemsId
    };

    var response = await Api.get(url: Api.getItemApi, queryParameters: body);

    if (!response[Api.error]) {
      List list = response['data'];
      itemData = list.map((model) => ItemModel.fromJson(model)).toList();
    } else {
      throw CustomException(response[Api.message]);
    }
    return itemData;
  }

  // Mark provider notifications as read
  void _markNotificationsAsRead() {
    // Only mark as read for providers
    final isProvider = HiveUtils.getUserType() == "Expert" || HiveUtils.getUserType() == "Business";

    if (!isProvider) return;

    // Instead of using a custom endpoint, let's update the notifications
    // locally and count them as read when displayed
    context.read<FetchNotificationsCubit>().fetchNotifications().then((_) {
      // We can update the state in the UI to reflect notifications as read
      // This is a visual change, as the backend might not support direct "mark as read"
      developer.log('Notifications fetched and displayed as read');
    }).catchError((error) {
      developer.log('Error fetching notifications: $error');
    });
  }
}
