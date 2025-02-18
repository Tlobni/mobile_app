import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class SomethingWentWrong extends StatelessWidget {
  final FlutterErrorDetails? error;

  const SomethingWentWrong({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: UiUtils.getSvg(
        AppIcons.somethingWentWrong,
      ),
    );
  }
}

class NoChatFound extends StatelessWidget {
  const NoChatFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        //crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UiUtils.getSvg(
            AppIcons.no_chat_found,
          ),
          const SizedBox(
            height: 20,
          ),
          CustomText(
            "No chat found. Start a new conversation",
            //"noChatFound".translate(context),
            fontSize: context.font.larger,
            color: context.color.territoryColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final StackTrace stack;

  const ErrorScreen({super.key, required this.stack});

  void _generateError(context) {
    final filteredStackLines = stack.toString().split('\n').where((line) {
      return !line.contains('package:flutter');
    }).map((line) {
      final parts = line.split(' ');
      return parts.length > 1 ? parts[1] : line;
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ErrorDetailScreen(stackLines: filteredStackLines),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _generateError(context);
      },
      child: const CustomText('Generate Error'),
    );
  }
}

class ErrorDetailScreen extends StatelessWidget {
  final List<String> stackLines;

  const ErrorDetailScreen({super.key, required this.stackLines});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText('Filtered and Prettified Error Stack Trace'),
      ),
      body: ListView.builder(
        itemCount: stackLines.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: CustomText(_formatStackTraceLine(stackLines[index])),
          );
        },
      ),
    );
  }
}

String _formatStackTraceLine(String line) {
  // Example format: "at Class.method (file.dart:42:23)"
  final startIndex = line.indexOf('at ') + 3;
  final endIndex = line.lastIndexOf('(');
  return line.substring(startIndex, endIndex);
}
