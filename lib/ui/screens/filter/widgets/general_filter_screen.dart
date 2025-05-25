import 'package:flutter/material.dart';
import 'package:tlobni/ui/screens/filter/widgets/filter_section.dart';
import 'package:tlobni/ui/widgets/buttons/primary_button.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';

class GeneralFilterScreen extends StatelessWidget {
  const GeneralFilterScreen({
    super.key,
    required this.title,
    required this.onResetPressed,
    required this.onApplyPressed,
    required this.sections,
  });

  final String title;
  final VoidCallback onResetPressed;
  final VoidCallback onApplyPressed;
  final List<dynamic> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _topBar(),
          ),
          const Divider(height: 1.5, color: Color(0xffe4dfd9), thickness: 0.8),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections
                      .map((e) => e is Widget
                          ? e
                          : e is (String, Widget)
                              ? FilterSection(title: e.$1, child: e.$2)
                              : Container())
                      .spaceBetween(30)
                      .toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _bottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Builder(builder: (context) {
      return Row(
        children: [
          Expanded(child: HeadingText(title)),
          SizedBox(width: 10),
          UnelevatedRegularButton(
            onPressed: () => Navigator.pop(context),
            color: const Color(0xffebebee),
            shape: CircleBorder(),
            padding: EdgeInsets.all(7),
            child: Icon(Icons.close, color: context.color.primary, size: 25),
          ),
        ],
      );
    });
  }

  Widget _bottomBar() => Row(
        children: [
          (4, _resetButton()),
          (9, _applyFilterButton()),
        ].mapExpandedSpaceBetween(10),
      );

  Widget _resetButton() => Builder(builder: (context) {
        return PrimaryButton.text(
          'Reset',
          padding: EdgeInsets.all(18),
          onPressed: onResetPressed,
          color: Color(0xfffafafa),
          border: BorderSide(color: context.color.primary),
          textColor: context.color.primary,
          fontSize: 16,
        );
      });

  Widget _applyFilterButton() => PrimaryButton.text(
        'Apply Filters',
        onPressed: onApplyPressed,
        padding: EdgeInsets.all(18),
        fontSize: 16,
      );
}
