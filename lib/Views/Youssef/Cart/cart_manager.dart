import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartManager extends ChangeNotifier {
  final List<Map<String, dynamic>> cartItems = [];
  String? _currentUserId;

  CartManager() {
    _initAuthListener();
  }

  // ✨ LISTEN TO AUTH CHANGES
  void _initAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.signedOut) {
        // ✨ USER LOGGED OUT - CLEAR CART
        clearCart();
        _currentUserId = null;
        print('🗑️ Cart cleared on logout');
      } else if (event == AuthChangeEvent.signedIn) {
        // ✨ USER LOGGED IN - SET USER ID
        _currentUserId = Supabase.instance.client.auth.currentUser?.id;
        print('✅ New user logged in: $_currentUserId');
      }
    });
  }

  // ✨ ADD WITH STRING PARAMETERS
  void addToCart(String id, String title, double price, String category, {int qty = 1}) {
    final existing = cartItems.firstWhere(
          (item) => item['id'] == id,
      orElse: () => {},
    );

    if (existing.isNotEmpty) {
      existing['qty'] += qty;
    } else {
      cartItems.add({
        'id': id,
        'title': title,
        'qty': qty,
        'price': price,
        'category': category,
      });
    }

    print('✅ Added to cart: $title');
    notifyListeners();
  }

  void removeItem(String id) {
    cartItems.removeWhere((item) => item['id'] == id);
    print('🗑️ Removed from cart');
    notifyListeners();
  }

  void clearCart() {
    cartItems.clear();
    print('🗑️ Cart cleared');
    notifyListeners();
  }

  double get totalPrice => cartItems.fold(
    0.0,
        (sum, item) => sum + (item['price'] * item['qty']),
  );

  bool get hasItems => cartItems.isNotEmpty;
  int get itemCount => cartItems.length;

  // ✨ CAPTCHA DIALOG
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

// ✨ CAPTCHA WEBVIEW
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
            controller.evaluateJavascript(
              source: "window.dispatchEvent(new Event('flutterInAppWebViewPlatformReady'));",
            );
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
