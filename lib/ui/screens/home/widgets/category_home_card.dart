import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';

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
    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            if (isFullImage) ...[
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: context.color.secondaryColor,
                  border: Border.all(
                      color: context.color.borderColor.darken(60), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: UiUtils.imageType(url, fit: BoxFit.cover),
              ),
            ] else ...[
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: context.color.borderColor.darken(60), width: 1),
                  color: context.color.secondaryColor,
                ),
                clipBehavior: Clip.antiAlias,
                child: UiUtils.imageType(url, fit: BoxFit.contain),
              ),
            ],
            Expanded(
                child: CustomText(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              fontSize: context.font.smaller,
              color: context.color.textDefaultColor,
            ))
          ],
        ),
      ),
    );
  }
}
