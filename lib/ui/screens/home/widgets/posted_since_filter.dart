import 'package:eClassify/ui/screens/filter_screen.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class PostedSinceFilterScreen extends StatefulWidget {
  final List<PostedSinceItem> list;
  final String postedSince;
  final Function update;

  const PostedSinceFilterScreen({
    Key? key,
    required this.list,
    required this.postedSince,
    required this.update,
  }) : super(key: key);

  @override
  State<PostedSinceFilterScreen> createState() => _PostedSinceFilterState();

  static Route route(RouteSettings routeSettings) {
    Map? args = routeSettings.arguments as Map?;
    return BlurredRouter(
      builder: (_) => PostedSinceFilterScreen(
        list: args?['list'],
        postedSince: args?['postedSince'],
        update: args?['update'],
      ),
    );
  }
}

class _PostedSinceFilterState extends State<PostedSinceFilterScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: "postedSinceLbl".translate(context),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Container(
          color: context.color.secondaryColor,
          child: ListView.separated(
            itemCount: widget.list.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) {
              return const Divider(
                thickness: 1.2,
                height: 10,
              );
            },
            itemBuilder: (context, index) {
              return ListTile(
                title: CustomText(
                  widget.list[index].status,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  color: context.color.textDefaultColor,
                  fontSize: context.font.normal,
                  fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w500,
                ),
                onTap: () {
                  // Handle item selection here
                  widget.update(widget.list[index].value);
                  Navigator.pop(context); // Close the screen after selection
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
