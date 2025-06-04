import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_picker/country_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tlobni/data/helper/custom_exception.dart';
import 'package:tlobni/settings.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

enum MessageType {
  success(successMessageColor),
  warning(warningMessageColor),
  error(errorMessageColor);

  final Color value;

  const MessageType(this.value);
}

void showCountryCode(BuildContext context, void Function(Country value) onSelect) {
  showCountryPicker(
    context: context,
    showWorldWide: false,
    showPhoneCode: true,
    exclude: ['IL'],
    favorite: ['LB'],
    countryListTheme: CountryListThemeData(
      borderRadius: BorderRadius.circular(11),
      searchTextStyle: TextStyle(
        color: context.color.textColorDark,
        fontSize: 16,
      ),
    ),
    onSelect: onSelect,
  );
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}

class HelperUtils {
  static void launchWhatsapp(String? phone) {
    if (phone == null) return;
    String url = Platform.isAndroid ? "https://wa.me/$phone" : "https://api.whatsapp.com/send?phone=$phone"; // new line

    launchUrl(Uri.parse(url));
  }

  static String decryptString(String encryptedText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8("0123456789123456"), mode: encrypt.AESMode.cbc));

      final encryptedValue = encrypt.Encrypted.fromBase64(encryptedText);
      final ivBytes = encrypt.IV.fromUtf8("DFGDxdfdfEREfgvC");

      final decrypted = encrypter.decrypt(encryptedValue, iv: ivBytes);

      return decrypted;
    } catch (e) {
      return encryptedText;
    }
  }

  static Future<bool> checkInternet() async {
    bool check = false;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      check = true;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      check = true;
    }
    return check;
  }

  static String checkHost(String url) {
    if (url.endsWith("/")) {
      return url;
    } else {
      return "$url/";
    }
  }

  static Future<void> precacheSVG(List<String> urls) async {
    for (String imageUrl in urls) {
      var loader = SvgAssetLoader(imageUrl);
      await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
    }
  }

  static int comparableVersion(String version) {
    //removing dot from version and parsing it into int
    String plain = version.replaceAll(".", "");

    return int.parse(plain);
  }

  static String nativeDeepLinkUrlOfItem(String itemSlug) {
    return "https://${AppSettings.shareNavigationWebUrl}/product-details/$itemSlug?share=true";
  }

  static void share(BuildContext context, String itemSlug) async {
    String deepLink = "";

    if (AppSettings.deepLinkingType == DeepLinkType.native) {
      deepLink = nativeDeepLinkUrlOfItem(itemSlug);
    }

    final box = context.findRenderObject() as RenderBox?;

    String text =
        "Exciting find! 🏡 Check out this amazing item I came across.  Let me know what you think! ⭐\n Here are the details:\n$deepLink.";
    await Share.share(text, sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    // showModalBottomSheet(
    //   context: context,
    //   backgroundColor: context.color.backgroundColor,
    //   builder: (context) {
    //     return Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         ListTile(
    //           leading: const Icon(Icons.copy),
    //           title: CustomText("copylink".translate(context)),
    //           onTap: () async {
    //             String deepLink = "";
    //             if (AppSettings.deepLinkingType == DeepLinkType.native) {
    //               deepLink = nativeDeepLinkUrlOfItem(itemSlug);
    //             }
    //
    //             await Clipboard.setData(ClipboardData(text: deepLink));
    //
    //             Future.delayed(Duration.zero, () {
    //               Navigator.pop(context);
    //               HelperUtils.showSnackBarMessage(context, "copied".translate(context));
    //             });
    //           },
    //         ),
    //         ListTile(
    //           leading: const Icon(Icons.share),
    //           title: CustomText("share".translate(context)),
    //           onTap: () async {
    //             String deepLink = "";
    //
    //             if (AppSettings.deepLinkingType == DeepLinkType.native) {
    //               deepLink = nativeDeepLinkUrlOfItem(itemSlug);
    //             }
    //
    //             final box = context.findRenderObject() as RenderBox?;
    //
    //             String text =
    //                 "Exciting find! 🏡 Check out this amazing item I came across.  Let me know what you think! ⭐\n Here are the details:\n$deepLink.";
    //             await Share.share(text, sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    //           },
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

  static void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static bool checkIsUserInfoFilled({String name = "", String email = ""}) {
    String chkname = name;
    if (name.trim().isEmpty) {
      // chkname = Constant.session.getStringData(Session.keyUserName);
    }
    return chkname.trim().isNotEmpty;
  }

  static String mobileNumberWithoutCountryCode() {
    String? mobile = HiveUtils.getUserDetails().mobile;

    String? countryCode = HiveUtils.getCountryCode();

    int countryCodeLength = (countryCode?.length ?? 0);

    String mobileNumber = mobile!.substring(countryCodeLength, mobile.length);

    return mobileNumber;
  }

  static dynamic showSnackBarMessage(BuildContext context, String message,
      {int messageDuration = 3, MessageType? type, bool? isFloating, VoidCallback? onClose}) async {
    var snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(message),
        behavior: (isFloating ?? false) ? SnackBarBehavior.floating : null,
        backgroundColor: type?.value,
        duration: Duration(seconds: messageDuration),
      ),
    );
    var snackBarClosedReason = await snackBar.closed;
    if (SnackBarClosedReason.values.contains(snackBarClosedReason)) {
      onClose?.call();
    }
  }

  static Future<String> getJsonResponse(BuildContext context,
      {bool isfromfile = false, StreamedResponse? streamedResponse, Response? response}) async {
    int code;
    if (isfromfile) {
      code = streamedResponse!.statusCode;
    } else {
      code = response!.statusCode;
    }
    switch (code) {
      case 200:
        if (isfromfile) {
          var responseData = await streamedResponse!.stream.toBytes();
          return String.fromCharCodes(responseData);
        } else {
          return response!.body;
        }

      case 400:
        throw BadRequestException(response!.body.toString());
      case 401:
        Map getdata = {};
        if (isfromfile) {
          var responseData = await streamedResponse!.stream.toBytes();
          getdata = json.decode(String.fromCharCodes(responseData));
        } else {
          getdata = json.decode(response!.body);
        }

        Future.delayed(
          Duration.zero,
          () {
            showSnackBarMessage(context, getdata[Api.message]);
          },
        );
        throw UnauthorisedException(getdata[Api.message]);
      case 403:
        throw UnauthorisedException(response!.body.toString());
      case 500:
      default:
        throw FetchDataException('Error occurred while Communication with Server with StatusCode: $code');
    }
  }

  static String getFileSizeString({required int bytes, int decimals = 0}) {
    const suffixes = ["b", "kb", "mb", "gb", "tb"];
    if (bytes == 0) return '0${suffixes[0]}';
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
  }

  static void killPreviousPages(BuildContext context, var nextpage, var args) {
    Navigator.of(context).pushNamedAndRemoveUntil(nextpage, (route) => false, arguments: args);
  }

  static void goToNextPage(var nextpage, BuildContext bcontext, bool isreplace, {Map? args}) {
    if (isreplace) {
      Navigator.of(bcontext).pushReplacementNamed(nextpage, arguments: args);
    } else {
      Navigator.of(bcontext).pushNamed(nextpage, arguments: args);
    }
  }

  static String setFirstLetterUppercase(String value) {
    if (value.isNotEmpty) value = value.replaceAll("_", ' ');
    return value.toTitleCase();
  }

  static Widget checkVideoType(String url, {required Widget Function() onYoutubeVideo, required Widget Function() onOtherVideo}) {
    List youtubeDomains = ["youtu.be", "youtube.com"];

    Uri uri = Uri.parse(url);
    var host = uri.host.toString().replaceAll("www.", "");
    if (youtubeDomains.contains(host)) {
      return onYoutubeVideo.call();
    } else {
      return onOtherVideo.call();
    }
  }

  static bool isYoutubeVideo(String url) {
    List youtubeDomains = ["youtu.be", "youtube.com"];

    Uri uri = Uri.parse(url);
    var host = uri.host.toString().replaceAll("www.", "");
    if (youtubeDomains.contains(host)) {
      return true;
    } else {
      return false;
    }
  }

  static Future<File> compressImageFile(File file) async {
    try {
      final int fileSize = await file.length();

      if (fileSize <= Constant.maxSizeInBytes) {
        // No need to compress if already within size limit
        return file;
      }

      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.png|.jp'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_out${filePath.substring(lastIndex)}";

      XFile? result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: Constant.uploadImageQuality,
      );

      return File(result!.path);
    } catch (e) {
      throw Exception("Error compressing image: $e");
    }
  }

  static void launchPathURL({
    required bool isTelephone,
    required bool isSMS,
    required bool isMail,
    required String value,
    required BuildContext context,
  }) async {
    late Uri redirectUri;

    if (isTelephone) {
      redirectUri = Uri.parse("tel:$value");
    } else if (isMail) {
      redirectUri = Uri(
        scheme: 'mailto',
        path: value,
        query: 'subject=${Constant.appName}&body=${"mailMsgLbl".translate(context)}',
      );
    } else if (isSMS) {
      redirectUri = Uri.parse("sms:$value");
    } else {
      redirectUri = Uri.parse('http://$value');
    }

    if (await canLaunchUrl(redirectUri)) {
      await launchUrl(redirectUri);
    } else {
      throw 'Could not launch $redirectUri';
    }
  }
}
