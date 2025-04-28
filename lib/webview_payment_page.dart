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
            try {
              String html = await _controller
                  .runJavaScriptReturningResult(
                  "document.documentElement.innerText") as String;

              // Clean up extra quotes if needed
              html = html.trim();
              if (html.startsWith('"') && html.endsWith('"')) {
                html = html.substring(1, html.length - 1);
                html = html.replaceAll(r'\"', '"'); // fix escaped quotes
              }

              debugPrint("Finished URL: $url \nHTML Content: $html");

              if (html.isNotEmpty) {
                final jsonData = jsonDecode(html);

                if (jsonData['key'] == 'success') {
                  if (widget.onSuccess != null) {
                    widget.onSuccess!.call();
                  } else {
                    Navigator.of(context).pop();
                  }
                } else if (jsonData['key'] == 'fail') {
                  if (widget.onFailure != null) {
                    widget.onFailure!.call();
                  } else {
                    Navigator.of(context).pop();
                  }
                }
              }
            } catch (e) {
              debugPrint("Error parsing or processing HTML: $e");
              if (widget.onFailure != null) {
                widget.onFailure!.call();
              } else {
                Navigator.of(context).pop();
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
