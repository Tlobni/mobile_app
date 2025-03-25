import 'package:tlobni/utils/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String authorizationUrl;
  final String? reference;
  final Function(String) onSuccess;
  final Function(String) onFailed;
  final Function() onCancel;

  const PaymentWebView({
    Key? key,
    required this.authorizationUrl,
    this.reference,
    required this.onSuccess,
    required this.onFailed,
    required this.onCancel,
  }) : super(key: key);

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onNavigationRequest: (NavigationRequest request) {
            final uri = request.url;
            print("uri***${uri.toString()}");
            if (uri.contains("Completed") ||
                uri.contains("completed") ||
                uri.toLowerCase().contains("success")) {
              widget.onSuccess(widget.reference ?? '');
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the WebView
              return NavigationDecision.prevent;
            } else if (uri.contains("Failed") || uri.contains("failed")) {
              widget.onFailed(widget.reference ?? '');

              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the WebView
              return NavigationDecision.prevent;
            } else {
              /* widget.onCancel();

              Navigator.of(context).pop();
              Navigator.of(context).pop();*/ // Close the WebView
              return NavigationDecision.navigate;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onCancel();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
