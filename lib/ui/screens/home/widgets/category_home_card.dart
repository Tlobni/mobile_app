import 'package:flutter/material.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class CategoryHomeCard extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onTap;

  const CategoryHomeCard({
    super.key,
    required this.title,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String extension = url.split(".").last.toLowerCase();
    bool isFullImage = false;

    if (extension == "png" || extension == "svg") {
      isFullImage = false;
    } else {
      isFullImage = true;
    }
    return Container(
      width: 100,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.color.borderColor.darken(60), width: 1),
                color: const Color(0xFFE6CBA8),
              ),
              padding: EdgeInsets.all(10),
              clipBehavior: Clip.antiAlias,
              child: UiUtils.imageType(url, fit: isFullImage ? BoxFit.cover : BoxFit.contain),
            ),
            SizedBox(height: 15),
            Expanded(
              child: DescriptionText(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                fontSize: 14,
                weight: FontWeight.w500,
                height: 1.5,
              ),
            )
          ],
        ),
      ),
    );
  }
}
