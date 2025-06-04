import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/tlobni-logo.png',
        height: 100,
        width: 180,
      ),
    );
  }
}
