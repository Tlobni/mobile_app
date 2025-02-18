import 'package:cached_network_image/cached_network_image.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

const double defaultPadding = 20;

Widget setNetworkImg(String? mainUrl,
    {double? height,
    double? width,
    Color? imgColor,
    BoxFit boxFit = BoxFit.contain,
    BoxFit? placeboxfit}) {
  String url = mainUrl ??= "";
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: boxFit,
    errorWidget: (context, url, error) {
      return setSVGImage("placeholder",
          height: height, width: width, boxFit: placeboxfit ?? boxFit);
    },
    placeholder: (context, url) {
      return Center(
          child: setSVGImage("placeholder",
              height: height, width: width, boxFit: placeboxfit ?? boxFit));
    },
  );
}

Widget setSVGImage(String imageName,
    {double? height,
    double? width,
    Color? imgColor,
    BoxFit boxFit = BoxFit.contain}) {
  String path = "$svgPath$imageName.svg";
  return SvgPicture.asset(
    path,
    height: height,
    width: width,
    colorFilter:
        imgColor != null ? ColorFilter.mode(imgColor, BlendMode.srcIn) : null,
    fit: boxFit,
  );
}
