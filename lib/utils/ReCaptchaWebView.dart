import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ReCaptchaWebView extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final void Function(String token) onTokenReceived;

  const ReCaptchaWebView({
    Key? key,
    required this.url,
    required this.width,
    required this.height,
    required this.onTokenReceived,
  }) : super(key: key);

  @override
  State<ReCaptchaWebView> createState() => _ReCaptchaWebViewState();
}

class _ReCaptchaWebViewState extends State<ReCaptchaWebView> {
  late InAppWebViewController _controller;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(widget.url),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              javaScriptCanOpenWindowsAutomatically: true,
              useHybridComposition: true,
              supportZoom: false,
              builtInZoomControls: false,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;

              controller.addJavaScriptHandler(
                handlerName: 'onTokenReceived',
                callback: (args) {
                  if (args.isNotEmpty) {
                    String token = args[0].toString();
                    print('✅ Received reCAPTCHA v2 token: ${token.substring(0, 30)}...');
                    widget.onTokenReceived(token);
                  }
                },
              );
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });

              controller.evaluateJavascript(source: """
                window.dispatchEvent(new Event('flutterInAppWebViewPlatformReady'));
              """);
            },
            onConsoleMessage: (controller, consoleMessage) {
              print('WebView Console: ${consoleMessage.message}');
            },
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading security verification...'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}