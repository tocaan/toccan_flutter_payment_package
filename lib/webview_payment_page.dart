import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPaymentPage extends StatefulWidget {
  final String url;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const WebViewPaymentPage({
    super.key,
    required this.url,
    this.onSuccess,
    this.onFailure,
  });

  @override
  _WebViewPaymentPageState createState() => _WebViewPaymentPageState();
}

class _WebViewPaymentPageState extends State<WebViewPaymentPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            String html = await _controller.runJavaScriptReturningResult(
                "document.documentElement.innerText") as String;
            debugPrint("Finished URL: $url \nHTML: $html");

            if (html.isNotEmpty) {
              try {
                var decoded = jsonDecode(html);

                // Sometimes html has outer quotes -> decoded becomes String not Map
                if (decoded is String) {
                  decoded =
                      jsonDecode(decoded); // Decode again if it's still String
                }

                if (decoded is Map<String, dynamic>) {
                  String key = decoded['key'] ?? '';

                  debugPrint('Extracted key: $key');

                  if (key == 'fail') {
                    debugPrint('Payment failed, please try again.');
                    if (mounted) {
                      if (widget.onFailure != null) {
                        widget.onFailure!.call();
                      } else {
                        Navigator.of(context).pop();
                      }
                    }
                  } else if (key == 'success') {
                    if (mounted) {
                      if (widget.onSuccess != null) {
                        widget.onSuccess!.call();
                      } else {
                        Navigator.of(context).pop();
                      }
                    }
                    debugPrint('Payment successful!');
                  }
                } else {
                  debugPrint('Decoded result is not a Map');
                }
              } catch (e) {
                debugPrint('Error decoding html: $e');
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CupertinoNavigationBar(
        middle: Text(
          "Payment",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        border: Border.fromBorderSide(BorderSide.none),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[200],
      body: WebViewWidget(controller: _controller),
    );
  }
}
