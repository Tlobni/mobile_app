// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:tlobni/ui/theme/theme.dart';

const kColorNavyBlue = Color(0xFF0D233F);
const kColorSecondaryBeige = Color(0xFFE7CCA8);
const kColorBackground = Color(0xFFFAFAFA);
const kColorGrey = Color(0xFF7A7A7A);

enum AppTheme { dark, light }

ThemeData appThemeData(AppTheme theme) => switch (theme) {
      AppTheme.light => ThemeData(
          // scaffoldBackgroundColor: pageBackgroundColor,
          brightness: Brightness.light,
          //textTheme
          useMaterial3: false,
          fontFamily: "Manrope",
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: territoryColor_,
            cursorColor: territoryColor_,
            selectionHandleColor: territoryColor_,
          ),
          buttonTheme: _buttonTheme(AppTheme.light),
          iconTheme: _iconTheme(AppTheme.light),
          switchTheme: _switchTheme(AppTheme.light),
          colorScheme: _colorScheme(AppTheme.light),
          textTheme: _textTheme(AppTheme.light),
        ),
      AppTheme.dark => ThemeData(
          brightness: Brightness.dark,
          useMaterial3: false,
          fontFamily: "Manrope",
          textButtonTheme: _textButtonTheme(AppTheme.dark),
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: territoryColorDark,
            selectionColor: territoryColorDark,
            cursorColor: territoryColorDark,
          ),
          buttonTheme: _buttonTheme(AppTheme.dark),
          colorScheme: _colorScheme(AppTheme.dark),
          iconTheme: _iconTheme(AppTheme.dark),
          switchTheme: _switchTheme(AppTheme.dark),
          textTheme: _textTheme(AppTheme.dark),
        )
    };

WidgetStateProperty<Color> _onSelectedAndOffColor(Color onSelectedColor, Color offColor) => WidgetStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return onSelectedColor;
      }
      return offColor;
    });

SwitchThemeData _switchTheme(AppTheme theme) => SwitchThemeData(
      thumbColor: _onSelectedAndOffColor(kColorNavyBlue, Color(0xffefefef)),
      trackColor: _onSelectedAndOffColor(kColorSecondaryBeige, Color(0xffe0e0e0)),
    );

IconThemeData _iconTheme(AppTheme theme) => IconThemeData(
      color: theme == AppTheme.light ? kColorNavyBlue : kColorSecondaryBeige,
    );

TextButtonThemeData _textButtonTheme(AppTheme theme) => TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(_textTheme(theme).bodyLarge),
      ),
    );

ButtonThemeData _buttonTheme(AppTheme theme) => ButtonThemeData(
      colorScheme: _colorScheme(theme),
    );

ColorScheme _colorScheme(AppTheme theme) {
  return (theme == AppTheme.light
          ? ColorScheme.light(
              primaryContainer: Colors.white,
            )
          : ColorScheme.dark())
      .copyWith(
    primary: kColorNavyBlue,
    onPrimary: kColorSecondaryBeige,
    secondary: kColorSecondaryBeige,
    onSecondary: kColorNavyBlue,
  );
}

TextTheme _textTheme(AppTheme theme) {
  final general = TextStyle(
    color: theme == AppTheme.light ? kColorNavyBlue : kColorSecondaryBeige,
  );
  return TextTheme(
    bodySmall: general.copyWith(fontSize: 14, fontFamily: 'Montserrat'),
    bodyMedium: general.copyWith(fontSize: 18, fontFamily: 'Montserrat'),
    bodyLarge: general.copyWith(fontSize: 20, fontFamily: 'Inter'),
    titleMedium: general.copyWith(fontSize: 30, fontFamily: 'Inter'),
  );
}
