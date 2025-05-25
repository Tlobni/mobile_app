import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/validator.dart';

enum CustomTextFieldValidator { nullCheck, phoneNumber, email, password, maxFifty, otpSix, minAndMixLen, url, slug }

class CustomTextFormField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final int? minLine;
  final int? maxLine;
  final bool? isReadOnly;
  final List<TextInputFormatter>? formaters;
  final CustomTextFieldValidator? validator;
  final Color? fillColor;
  final Function(dynamic value)? onChange;
  final Widget? prefix;
  final TextInputAction? action;
  final TextInputType? keyboard;
  final Widget? suffix;
  final bool? dense;
  final Color? borderColor;
  final Widget? fixedPrefix;
  final bool? obscureText;
  final int? maxLength;
  final int? minLength;
  final TextStyle? hintTextStyle;
  final TextCapitalization? capitalization;
  final bool? isRequired;
  final bool? isMobileRequired;
  final bool? readOnly;
  final VoidCallback? onTap;

  const CustomTextFormField({
    super.key,
    this.hintText,
    this.controller,
    this.minLine,
    this.maxLine,
    this.formaters,
    this.isReadOnly,
    this.validator,
    this.fillColor,
    this.onChange,
    this.prefix,
    this.keyboard,
    this.action,
    this.suffix,
    this.dense,
    this.borderColor,
    this.fixedPrefix,
    this.obscureText,
    this.maxLength,
    this.hintTextStyle,
    this.minLength,
    this.capitalization,
    this.isRequired,
    this.isMobileRequired = true,
    this.readOnly,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor ?? context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        inputFormatters: formaters,
        obscureText: obscureText ?? false,
        textInputAction: action,
        onTapOutside: (PointerDownEvent event) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        keyboardAppearance: Brightness.light,
        textCapitalization: capitalization ?? TextCapitalization.none,
        readOnly: readOnly ?? false,
        style: context.textTheme.bodyMedium,
        minLines: minLine ?? 1,
        maxLines: maxLine ?? 1,
        onChanged: onChange,
        validator: (String? value) {
          if (validator == CustomTextFieldValidator.nullCheck) {
            return Validator.nullCheckValidator(value, context: context);
          }

          if (validator == CustomTextFieldValidator.maxFifty) {
            if ((value ??= "").length > 50) {
              return "youCanEnter50LettersMax".translate(context);
            } else {
              return null;
            }
          }

          // Check if maxLength is not null and value length exceeds maxLength
          if (validator == CustomTextFieldValidator.minAndMixLen) {
            // Check if the value is empty
            if (isRequired == true && value == "") {
              return Validator.nullCheckValidator(value, context: context);
            }

            if (isRequired == true && (maxLength != null && value!.length > maxLength!)) {
              return "${"youCanAdd".translate(context)} \t $maxLength \t ${"maximumNumbersOnly".translate(context)}";
            }

            // Check if minLength is not null and value length is less than minLength
            if (isRequired == true && (minLength != null && value!.length < minLength!)) {
              return "$minLength \t ${"numMinRequired".translate(context)}";
            }
            return null;
          }

          if (validator == CustomTextFieldValidator.otpSix) {
            if ((value ??= "").length != 6) {
              return 'pleaseEnterSixDigits'.translate(context);
            }
            return null;
          }
          if (validator == CustomTextFieldValidator.email) {
            return Validator.validateEmail(email: value, context: context);
          }
          if (validator == CustomTextFieldValidator.slug) {
            return Validator.validateSlug(value, context: context);
          }
          if (validator == CustomTextFieldValidator.phoneNumber) {
            return Validator.validatePhoneNumber(value: value, context: context, isRequired: isMobileRequired!);
          }
          if (validator == CustomTextFieldValidator.url) {
            return Validator.urlValidation(value: value, context: context);
          }
          if (validator == CustomTextFieldValidator.password) {
            return Validator.validatePassword(value, context: context);
          }
          return null;
        },
        keyboardType: keyboard,
        maxLength: maxLength,
        decoration: InputDecoration(
          prefix: prefix,
          isDense: dense,
          prefixIcon: fixedPrefix,
          suffixIcon: suffix,
          hintText: hintText,
          hintStyle: hintTextStyle ?? context.textTheme.bodyMedium,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
        ),
        onTap: onTap,
      ),
    );
  }
}
