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

    debugPrint('✅ WebViewPaymentPage initialized - v1.0.2');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            debugPrint('✅ Page Finished loading: $url');

            try {
              String html = await _controller.runJavaScriptReturningResult(
                  "document.documentElement.innerText"
              ) as String;

              html = html.trim();
              if (html.startsWith('"') && html.endsWith('"')) {
                html = html.substring(1, html.length - 1);
                html = html.replaceAll(r'\"', '"');
              }

              debugPrint("✅ HTML Content: $html");

              if (html.isEmpty) {
                debugPrint("⚠️ HTML is empty. Waiting for next navigation...");
                return;
              }

              final dynamic firstDecoded = jsonDecode(html);

              if (firstDecoded is String) {
                final Map<String, dynamic> jsonData = jsonDecode(firstDecoded);
                _handlePaymentResult(jsonData);
              } else if (firstDecoded is Map<String, dynamic>) {
                _handlePaymentResult(firstDecoded);
              } else {
                debugPrint("⚠️ Unexpected JSON structure.");
                _handleFailure();
              }
            } catch (e) {
              debugPrint("❌ Error parsing or processing HTML: $e");
              _handleFailure();
            }
          },

          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🔵 Navigating to: ${request.url}');

            if (request.url.contains('payment-success')) {
              debugPrint('✅ Payment success detected by URL.');
              widget.onSuccess?.call();
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            } else if (request.url.contains('payment-fail') ||
                request.url.contains('payment-failed') ||
                request.url.contains('fail')) {
              debugPrint('❌ Payment failure detected by URL.');
              widget.onFailure?.call();
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _handlePaymentResult(Map<String, dynamic> jsonData) {
    final key = jsonData['key'];
    debugPrint('✅ Payment Result Key: $key');

    if (key == 'success') {
      widget.onSuccess?.call();
      Navigator.of(context).pop();
    } else if (key == 'fail') {
      widget.onFailure?.call();
      Navigator.of(context).pop();
    } else {
      debugPrint('⚠️ Unknown key: $key');
      _handleFailure();
    }
  }

  void _handleFailure() {
    widget.onFailure?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
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
