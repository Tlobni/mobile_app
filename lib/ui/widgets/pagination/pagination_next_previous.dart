import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';

class PaginationNextPrevious extends StatelessWidget {
  const PaginationNextPrevious({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.onButtonPressed,
  });

  final int currentPage;
  final int lastPage;
  final void Function(int newPage) onButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentPage != 1) (-1, 'Previous') else SizedBox(),
        if (currentPage != lastPage) (1, 'Next') else SizedBox(),
      ].map<Widget>((e) {
        if (e is Widget) return e;
        final (add, text) = e as (int, String);
        return TextButton(
          onPressed: () => onButtonPressed(currentPage + add),
          child: SmallText(text),
        );
      }).toList(),
    );
  }
}
