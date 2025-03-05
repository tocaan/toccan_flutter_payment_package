import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPaymentPage extends StatefulWidget {
  final String url;

  const WebViewPaymentPage({super.key, required this.url});

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
                Map<String, dynamic>? json = jsonDecode(html);
                if (json != null && json.containsKey("success")) {
                  if (mounted) {
                    Navigator.of(context).pop(json);
                  }
                }
              } catch (e) {
                debugPrint("Error parsing JSON: $e");
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
