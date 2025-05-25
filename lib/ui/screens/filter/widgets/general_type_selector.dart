import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';

class GeneralTypeSelector<T> extends StatelessWidget {
  const GeneralTypeSelector({super.key, required this.values, this.selectedValue, required this.valueToString, required this.onChanged});

  final List<T> values;
  final T? selectedValue;
  final String Function(T value) valueToString;
  final void Function(T? value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: values.map(_listingTypeButton).mapExpandedSpaceBetween(10),
    );
  }

  Widget _listingTypeButton(T value) => Builder(builder: (context) {
        return UnelevatedRegularButton(
          onPressed: () {
            onChanged(value == selectedValue ? null : value);
          },
          color: selectedValue == value ? context.color.primary : Colors.white,
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: context.color.primary),
          ),
          child: Center(
            child: SmallText(
              valueToString(value).translate(context),
              color: selectedValue == value ? context.color.onPrimary : null,
              fontSize: 13,
            ),
          ),
        );
      });
}
