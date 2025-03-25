import 'package:tlobni/ui/screens/widgets/video_view_screen.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class AllGalleryImages extends StatelessWidget {
  final List images;
  final String? youtubeThumbnail;

  const AllGalleryImages(
      {super.key, required this.images, this.youtubeThumbnail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
      ),
      body: GridView.builder(
        itemCount: images.length,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 5, mainAxisSpacing: 5),
        itemBuilder: (context, index) {
          return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: GestureDetector(
                onTap: () {
                  if (images[index].isVideo == true) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return VideoViewScreen(videoUrl: images[index].image);
                      },
                    ));
                  } else {
                    var stringImages = images.map((e) => e.imageUrl).toList();
                    UiUtils.imageGallaryView(
                      context,
                      images: stringImages,
                      initalIndex: index,
                      then: () {},
                    );
                  }
                },
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: images[index].isVideo == true
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            UiUtils.getImage(youtubeThumbnail!,
                                fit: BoxFit.cover),
                            const Icon(
                              Icons.play_arrow,
                              size: 28,
                            )
                          ],
                        )
                      : UiUtils.getImage(images[index].imageUrl ?? "",
                          fit: BoxFit.cover),
                ),
              ));
        },
      ),
    );
  }
}
