import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onTap;

  const CategoryCard({
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          border: Border.all(color: context.color.borderColor.darken(40)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            if (isFullImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.11, //94,
                  width: double.infinity,
                  color: context.color.territoryColor.withOpacity(0.1),
                  child: UiUtils.imageType(url,
                      fit: BoxFit.fill, color: context.color.territoryColor),
                ),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.11, //94,
                  color: context.color.territoryColor.withOpacity(0.1),
                  child: Center(
                    child: SizedBox(
                      // color: Colors.blue,
                      width: 48,
                      height: 48,
                      child: UiUtils.imageType(url,
                          fit: BoxFit.cover,
                          color: context.color.territoryColor),
                    ),
                  ),
                ),
              ),
            ],
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: CustomText(
                      title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      color: context.color.textColorDark,
                      fontSize: context.font.small,
                    )))
          ],
        ),
      ),
    );
  }
}
