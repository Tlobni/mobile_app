import 'package:cached_network_image/cached_network_image.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class GalleryViewWidget extends StatefulWidget {
  final List images;
  final int initalIndex;

  const GalleryViewWidget({
    super.key,
    required this.images,
    required this.initalIndex,
  });

  @override
  State<GalleryViewWidget> createState() => _GalleryViewWidgetState();

/*  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return BlurredRouter(
        builder: (_) => GalleryViewWidget(
            images: arguments?['images'],
            initalIndex: arguments?['initalIndex']));
  }*/
}

class _GalleryViewWidgetState extends State<GalleryViewWidget> {
  late PageController controller =
      PageController(initialPage: widget.initalIndex);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: UiUtils.buildAppBar(
          context,
          showBackButton: true,
          backgroundColor: context.color.secondaryDetailsColor,
        ),
        backgroundColor: context.color.secondaryDetailsColor,
        body: PageView.builder(
          controller: controller,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              scaleEnabled: true,
              maxScale: 5,
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                /*  memCacheHeight: 500,
                memCacheWidth: 500,*/
                errorWidget: (context, url, error) {
                  return Container(
                    color: context.color.territoryColor.withOpacity(0.1),
                    alignment: AlignmentDirectional.center,
                    child: SizedBox(
                      child: UiUtils.getSvg(
                        AppIcons.placeHolder,
                        width: 70,
                        height: 70,
                      ),
                    ),
                  );
                },
              ),
            );
          },
          itemCount: widget.images.length,
        ));
  }

/*  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
    */ /*  appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        */ /**/ /*iconTheme: IconThemeData(color: context.color.territoryColor),*/ /**/ /*
      ),*/ /*
      backgroundColor: const Color.fromARGB(17, 0, 0, 0),
      body: ScrollConfiguration(
        behavior: RemoveGlow(),
        child: PageView.builder(
          controller: controller,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              // panEnabled: true,
              scaleEnabled: true,
maxScale: 5,
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                memCacheHeight: 500,
                memCacheWidth: 500,

              ),
            );
          },
          itemCount:
              (widget.images..removeWhere((element) => (element == ""))).length,
        ),
      ),
    );
  }*/
}
