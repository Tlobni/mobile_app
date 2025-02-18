import 'package:eClassify/data/helper/designs.dart';
import 'package:eClassify/ui/screens/settings/notifications.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class NotificationDetail extends StatefulWidget {
  const NotificationDetail({super.key});

  @override
  State<NotificationDetail> createState() => _NotificationDetailState();

  static Route route(RouteSettings routeSettings) {
    return BlurredRouter(
      builder: (_) => const NotificationDetail(),
    );
  }
}

class _NotificationDetailState extends State<NotificationDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(context,
          title: "notifications".translate(context), showBackButton: true),
      body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 13.0, vertical: 13.0),
          children: <Widget>[
            if (selectedNotification.image!.isNotEmpty)
              setNetworkImg(selectedNotification.image!, boxFit: BoxFit.cover),
            const SizedBox(height: 10),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: detailWidget())
          ]),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Column detailWidget() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            selectedNotification.title!,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .merge(const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 5),
          Text(
            selectedNotification.message!,
            style: Theme.of(context).textTheme.bodySmall!,
          ),
        ]);
  }
}
