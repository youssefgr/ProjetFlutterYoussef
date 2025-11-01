import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CartManager {
  static final CartManager _instance = CartManager._internal();

  factory CartManager() => _instance;

  CartManager._internal();

  final List<Map<String, dynamic>> cartItems = [];

  void addToCart(Expenses expense, int qty) {
    final existing = cartItems.firstWhere(
          (item) => item['id'] == expense.id,
      orElse: () => {},
    );

    if (existing.isNotEmpty) {
      existing['qty'] += qty;
    } else {
      cartItems.add({
        'id': expense.id,
        'title': expense.title,
        'qty': qty,
        'price': expense.price,
        'category': expense.category.name,
      });
    }
  }

  void removeItem(String id) {
    cartItems.removeWhere((item) => item['id'] == id);
  }

  void clearCart() {
    cartItems.clear();
  }

  double get totalPrice => cartItems.fold(
    0.0,
        (sum, item) => sum + (item['price'] * item['qty']),
  );

  bool get hasItems => cartItems.isNotEmpty;

  int get itemCount => cartItems.length;

  // Show reCAPTCHA v2 dialog
  Future<String?> showCaptchaDialog(BuildContext context) async {
    String? token;
    bool dialogDismissed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Security Verification'),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _ReCaptchaV2WebView(
            onTokenReceived: (receivedToken) {
              if (!dialogDismissed) {
                dialogDismissed = true;
                token = receivedToken;
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!dialogDismissed) {
                dialogDismissed = true;
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    return token;
  }
}

// Private WebView widget for reCAPTCHA v2
class _ReCaptchaV2WebView extends StatefulWidget {
  final void Function(String token) onTokenReceived;

  const _ReCaptchaV2WebView({
    required this.onTokenReceived,
  });

  @override
  State<_ReCaptchaV2WebView> createState() => _ReCaptchaV2WebViewState();
}

class _ReCaptchaV2WebViewState extends State<_ReCaptchaV2WebView> {
  bool _isLoading = true;
  bool _tokenReceived = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('https://youssefgr.github.io/recaptchayoussef/recaptcha.html'),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            javaScriptCanOpenWindowsAutomatically: true,
            useHybridComposition: true,
            supportZoom: false,
            builtInZoomControls: false,
          ),
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(
              handlerName: 'onTokenReceived',
              callback: (args) {
                if (_tokenReceived || !mounted) return;

                if (args.isNotEmpty) {
                  _tokenReceived = true;
                  String token = args[0].toString();
                  print('✅ Received reCAPTCHA v2 token: ${token.substring(0, 30)}...');
                  widget.onTokenReceived(token);
                }
              },
            );
          },
          onLoadStart: (controller, url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onLoadStop: (controller, url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            controller.evaluateJavascript(source: """
              window.dispatchEvent(new Event('flutterInAppWebViewPlatformReady'));
            """);
          },
          onConsoleMessage: (controller, consoleMessage) {
            if (!consoleMessage.message.contains('Uncaught (in promise) null')) {
              print('WebView: ${consoleMessage.message}');
            }
          },
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
                  Text('Loading verification...'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}