import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/ui/screens/home/widgets/home_section.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/views/page_view_adaptable_height.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';

class HomeList extends StatefulWidget {
  const HomeList({
    super.key,
    required this.title,
    required this.onViewAll,
    required this.error,
    required this.isLoading,
    required this.shimmerEffect,
    required this.children,
    this.showBottomButtons = true,
  });

  final String title;
  final VoidCallback onViewAll;
  final bool isLoading;
  final Widget shimmerEffect;
  final List<Widget> children;
  final String? error;
  final bool showBottomButtons;

  @override
  State<HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {
  late final _controller = PageController()
    ..addListener(() => WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {});
        }));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: widget.title,
      onViewAll: widget.onViewAll,
      error: widget.error,
      isLoading: widget.isLoading,
      shimmerEffect: widget.shimmerEffect,
      isEmpty: widget.children.isEmpty,
      child: Column(
        children: [
          PageViewHeightAdaptable(
            children: widget.children,
            controller: _controller,
          ),
          if (widget.showBottomButtons)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < widget.children.length; i++)
                    Builder(builder: (context) {
                      void onPressed() => _controller.animateToPage(i, duration: Duration(milliseconds: 300), curve: Curves.linear);

                      return GestureDetector(
                        onTap: onPressed,
                        child: Container(
                          padding: EdgeInsets.all(15),
                          child: UnelevatedRegularButton(
                            onPressed: onPressed,
                            child: SizedBox(),
                            padding: EdgeInsets.all(5.2),
                            shape: CircleBorder(),
                            color: !_controller.hasClients || _controller.page == i ? kColorSecondaryBeige : context.color.primary,
                          ),
                        ),
                      );
                    }),
                ].spaceBetween(0).toList(),
              ),
            )
        ],
      ),
    );
  }
}
