// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: invalid_use_of_visible_for_testing_member

//import 'package:file_icon/src/data.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';

/// Note: Here i have used abstract factory pattern and builder pattern
/// You can learn design patterns from internet
/// so don't be confuse
List kDoNotReBuildThese = [];
List kDoNotReBuildDropdown = [];

abstract class AbstractField {
  final BuildContext context;
  static Map<String, dynamic> fieldsData = {};
  static Map<String, dynamic> files = {};

  AbstractField(this.context);

  Widget createField(Map parameters);
}

class CustomTextFieldDynamic extends StatefulWidget {
  final String? value;
  final bool initController;
  final dynamic id;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? action;
  final List<TextInputFormatter>? formaters;
  final bool? required;
  final CustomTextFieldValidator? validator;
  final int? minLen;
  final int? maxLen;
  final int? maxLine;
  final int? minLine;
  final TextCapitalization? capitalization;

  const CustomTextFieldDynamic({
    super.key,
    required this.initController,
    required this.value,
    this.id,
    required this.hintText,
    this.keyboardType,
    this.action,
    this.formaters,
    this.required,
    this.validator,
    this.minLen,
    this.maxLen,
    this.maxLine,
    this.minLine,
    this.capitalization,
  });

  @override
  State<CustomTextFieldDynamic> createState() => CustomTextFieldDynamicState();
}

class CustomTextFieldDynamicState extends State<CustomTextFieldDynamic> {
  TextEditingController? _controller;

  @override
  void initState() {
    if (widget.initController) {
      _controller = TextEditingController(text: widget.value);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      hintText: widget.hintText,
      action: widget.action,
      formaters: widget.formaters,
      isRequired: widget.required,
      validator: widget.validator!,
      keyboard: widget.keyboardType,
      controller: _controller,
      maxLength: widget.maxLen,
      minLength: widget.minLen,
      maxLine: widget.maxLine,
      minLine: widget.minLine,
      capitalization: widget.capitalization,
      onChange: (value) {
        AbstractField.fieldsData.addAll(Map<String, dynamic>.from({
          widget.id.toString(): [value]
        }));
      },
    );
  }
}
