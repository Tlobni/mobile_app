import 'package:flutter/material.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

///Light Theme Colors
///This color format is different, isn't it? .You can use hex colors here also but you have to remove '#' symbol and add 0xff instead.
const Color primaryColor_ = Color(0xFFF6F5FA);
const Color secondaryColor_ = Color(0xFFFFFFFF);
const Color territoryColor_ = Color(0xFF08213e);
const Color forthColor_ = Color(0xffFA6E53);
const Color _backgroundColor = primaryColor_; //here you can change if you need
const Color textDarkColor = Color(0xFF000000);
Color lightTextColor = const Color(0xFF000000).withOpacity(0.3);
Color widgetsBorderColorLight = const Color(0xffEEEEEE).withOpacity(0.6);
Color senderChatColor = const Color.fromARGB(255, 233, 233, 233).darken(22);

///Dark Theme Colors
Color primaryColorDark = const Color(0xff121212);
Color secondaryColorDark = const Color(0xff1C1C1C).brighten(5);
const Color territoryColorDark = Color(0xFF08213e);
Color deactivateColorLight = const Color(0xff7F7F7F);

const Color forthColorDark = Color(0xffFA6E53);
Color backgroundColorDark = primaryColorDark; //here you can change if you need
const Color textColorDarkTheme = Color(0xffFDFDFD);
Color lightTextColorDarkTheme = const Color(0xffFDFDFD).withOpacity(0.3);
Color widgetsBorderColorDark = const Color(0x1aFDFDFD);
//Color popUpColor = const Color(0xff02AD11);
Color darkSenderChatColor = const Color.fromARGB(255, 233, 233, 233).darken(100);

///Messages Color
const Color errorMessageColor = Color.fromARGB(255, 166, 4, 4); // Color(0xffeb5479)
const Color successMessageColor = Color(0xFF08213e);
const Color warningMessageColor = Color(0xFFC2AF6F);

//status button color
const Color pendingButtonColor = Color(0xff0C5D9C);
const Color soldOutButtonColor = Color(0xffFFBB33);
const Color deactivateButtonColor = Color(0xffFE0000);
const Color activateButtonColor = Color(0xFF02AD11);

//Button text color
const Color buttonTextColor = Color(0xFFCCBD86);

///Advance
//Theme settings
extension ColorPrefs on ColorScheme {
  Color get primaryColor => _getColor(brightness, lightColor: primaryColor_, darkColor: primaryColorDark);

  Color get secondaryColor => _getColor(brightness, lightColor: secondaryColor_, darkColor: secondaryColorDark);

  Color get secondaryDetailsColor => _getColor(brightness, lightColor: secondaryColor_, darkColor: primaryColorDark);

  Color get territoryColor => _getColor(brightness, lightColor: territoryColor_, darkColor: territoryColorDark);

  Color get deactivateColor => _getColor(brightness, lightColor: deactivateColorLight, darkColor: backgroundColorDark);

  Color get forthColor => _getColor(brightness, lightColor: forthColor_, darkColor: forthColorDark);

  Color get backgroundColor => _getColor(brightness, lightColor: _backgroundColor, darkColor: backgroundColorDark);

  Color get buttonColor => buttonTextColor;

  Color get textColorDark => _getColor(brightness, lightColor: textDarkColor, darkColor: textColorDarkTheme);

  Color get textDefaultColor => _getColor(brightness, lightColor: textDarkColor, darkColor: textColorDarkTheme);

  Color get textLightColor => _getColor(brightness, lightColor: lightTextColor, darkColor: lightTextColorDarkTheme);

  Color get borderColor => _getColor(brightness, lightColor: widgetsBorderColorLight, darkColor: secondaryColorDark.withOpacity(0.2));

  Color get chatSenderColor => _getColor(brightness, lightColor: senderChatColor, darkColor: darkSenderChatColor);

  ///This will set text color white if background is dark if background is light it will be dark
  Color textAutoAdapt(Color backgroundColor) => UiUtils.getAdaptiveTextColor(backgroundColor);

  Color get blackColor => Colors.black;

  Color get shimmerBaseColor =>
      brightness == Brightness.light ? const Color.fromARGB(255, 225, 225, 225) : const Color.fromARGB(255, 150, 150, 150);

  Color get shimmerHighlightColor => brightness == Brightness.light ? Colors.grey.shade100 : Colors.grey.shade300;

  Color get shimmerContentColor => brightness == Brightness.light ? Colors.white.withOpacity(0.85) : Colors.white.withOpacity(0.7);
}

// 10pt: Smaller
// 12pt: Small
// 16pt: Large
// 18pt: Larger
// 24pt: Extra large
extension TextThemeForFont on TextTheme {
  Font get font => Font();
}

/// i made this to access font easily from theme like, Theme.of(context).textTheme.font.small
/// So what is difference here?? in Theme.of(context).textTheme.small and Theme.of(context).textTheme.font.small
/// We use separate class because There will be an execution on BuildContext in [Utils/Extensions/lib] folder so further explanation is there. you can check
class Font {
  ///10
  double get smaller => 10;

  ///12
  double get small => 12;

  ///14
  double get normal => 14;

  ///16
  double get large => 16;

  ///18
  double get larger => 18;

  ///24
  double get extraLarge => 24;

  ///28
  double get xxLarge => 28;
}

Color _getColor(Brightness brightness, {required Color lightColor, required Color darkColor}) {
  if (Brightness.light == brightness) {
    return lightColor;
  } else {
    return darkColor;
  }
}
