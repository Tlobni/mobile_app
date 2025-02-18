import 'package:eClassify/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:eClassify/ui/screens/widgets/dynamic_field.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/validator.dart';
import 'package:flutter/material.dart';

class CustomRadioField extends CustomField {
  @override
  String type = "radio";
  String? selectedRadioValue;
  bool calledUpdate = false;
  FormFieldState<String>? validation;
  List? values;

  @override
  void init() {
    dynamic selectedCustomFieldValue = (parameters['values']);
    values = selectedCustomFieldValue;
    if (parameters['isEdit'] == true) {
      if (parameters['value'] != null) {
        if ((parameters['value'] as List).isNotEmpty) {
          selectedRadioValue = parameters['value'][0];
        }
      }
    }
    validation?.didChange((selectedCustomFieldValue[0]));

    update(() {});

    // selectedRadio.value = widget.radioValues?[index];

    super.init();
  }

  @override
  Widget render() {
    return CustomValidator<String>(
      initialValue: values![0],
      builder: (FormFieldState<String> state) {
        if (validation == null) {
          validation = state;
          Future.delayed(Duration.zero, () {
            update(() {});
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (parameters['image'] != null) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          context.color.territoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: FittedBox(
                        fit: BoxFit.none,
                        child: UiUtils.imageType(parameters['image'],
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            color: context.color.textDefaultColor),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                ],
                CustomText(
                  parameters['name'],
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w500,
                  color: context.color.textColorDark,
                )
              ],
            ),
            SizedBox(
              height: 14,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                    alignment: WrapAlignment.start,
                    runAlignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: List.generate(values!.length, (index) {
                      var element = values![index];

                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: index == 0 ? 0 : 4,
                          end: 4,
                          bottom: 4,
                          top: 4,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            if (selectedRadioValue == element) {
                              // Deselect if already selected
                              selectedRadioValue = null;
                            } else {
                              // Select the tapped option
                              selectedRadioValue = element;
                            }
                            //selectedRadioValue = element;
                            update(() {});
                            state.didChange(selectedRadioValue);

                            // selectedRadio.value = widget.radioValues?[index];
                            AbstractField.fieldsData.addAll({
                              parameters['id'].toString(): [selectedRadioValue]
                            });
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: context.color.borderColor,
                                      width: 1.5),
                                  color: selectedRadioValue == element
                                      ? context.color.territoryColor
                                          .withValues(alpha: 0.1)
                                      : context.color.secondaryColor,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  child: CustomText(values![index],
                                      color: (selectedRadioValue == element
                                          ? context.color.territoryColor
                                          : context.color.textDefaultColor)))),
                        ),
                      );
                    })),
                if (state.hasError)
                  Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 8.0),
                      child: CustomText(
                        state.errorText ?? "",
                        color: context.color.error,
                        fontSize: context.font.small,
                      ))
              ],
            )
          ],
        );
      },
      validator: (String? value) {
        // Check if the field is required

        // Check if the value is null or empty (no selection made)
        if (parameters['required'] == 1 &&
            (selectedRadioValue == null || selectedRadioValue!.isEmpty)) {
          return "Selecting this is required"; // Return the error message if no selection
        }

        // If a valid selection is made, return null to indicate no error
        return null;
      },
    );
  }
}
