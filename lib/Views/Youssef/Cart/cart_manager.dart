import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CartManager extends ChangeNotifier {
  List<Map<String, dynamic>> cartItems = [];

  // ✨ GET TOTAL PRICE
  double get totalPrice {
    return cartItems.fold<double>(0, (sum, item) {
      double price = (item['price'] as num).toDouble();
      int qty = (item['qty'] as num).toInt();
      return sum + (price * qty);
    });
  }

  // ✨ GET TOTAL QUANTITY
  int get totalQuantity {
    return cartItems.fold<int>(0, (sum, item) {
      int qty = (item['qty'] as num).toInt();
      return sum + qty;
    });
  }

  // ✨ CHECK IF CART HAS ITEMS
  bool get hasItems => cartItems.isNotEmpty;

  // ✨ ADD TO CART - ADD SINGLE ITEM WITH QUANTITY (NOT LOOP!)
  void addToCart(
      String id,
      String title,
      double price,
      String category, {
        int qty = 1,
      }) {
    print('🛒 Adding to cart: $title x$qty');

    final cartItem = {
      'id': id,
      'title': title,
      'price': price,
      'category': category,
      'qty': qty,
    };

    cartItems.add(cartItem);
    notifyListeners();

    print('✅ Cart updated: ${cartItems.length} items, Total: $totalPrice €');
  }

  // ✨ REMOVE FROM CART
  void removeFromCart(String id) {
    print('🗑️ Removing item: $id');
    cartItems.removeWhere((item) => item['id'] == id);
    notifyListeners();
    print('✅ Item removed. Cart: ${cartItems.length} items');
  }

  // ✨ ALIAS FOR COMPATIBILITY
  void removeItem(String id) {
    removeFromCart(id);
  }

  // ✨ UPDATE QUANTITY
  void updateQuantity(String id, int newQty) {
    print('📝 Updating $id quantity to $newQty');
    for (var item in cartItems) {
      if (item['id'] == id) {
        if (newQty <= 0) {
          removeFromCart(id);
        } else {
          item['qty'] = newQty;
          notifyListeners();
          print('✅ Quantity updated: $newQty');
        }
        return;
      }
    }
  }

  // ✨ CLEAR CART
  void clearCart() {
    print('🗑️ Clearing cart...');
    cartItems.clear();
    notifyListeners();
    print('✅ Cart cleared');
  }

  // ✨ GET ITEM BY ID
  Map<String, dynamic>? getItem(String id) {
    try {
      return cartItems.firstWhere((item) => item['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // ✨ GET ITEM QUANTITY
  int getItemQuantity(String id) {
    final item = getItem(id);
    return item != null ? (item['qty'] as num).toInt() : 0;
  }

  // ✨ SHOW CAPTCHA DIALOG - WITH INAPPWEBVIEW (ORIGINAL WORKING VERSION)
  Future<String?> showCaptchaDialog(BuildContext context) async {
    String? token;
    bool dialogDismissed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🔐 Security Verification'),
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

  // ✨ PRINT CART SUMMARY
  void printCartSummary() {
    print('\n📋 CART SUMMARY:');
    print('Items: ${cartItems.length}');
    print('Total Qty: $totalQuantity');
    print('Total Price: ${totalPrice.toStringAsFixed(2)} €');
    for (var item in cartItems) {
      // ✨ FIXED - Proper calculation without nested casts
      double subtotal = (item['price'] as num).toDouble() * (item['qty'] as num).toInt();
      print('  - ${item['title']} x${item['qty']} = ${subtotal.toStringAsFixed(2)} €');
    }
    print('');
  }
}

// ✨ PRIVATE WEBVIEW WIDGET FOR RECAPTCHA V2 (ORIGINAL WORKING VERSION)
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
            url: WebUri(
                'https://youssefgr.github.io/recaptchayoussef/recaptcha.html'),
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
                  print(
                      '✅ Received reCAPTCHA v2 token: ${token.substring(0, min(token.length, 30))}...');
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
            if (!consoleMessage.message
                .contains('Uncaught (in promise) null')) {
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

// ✨ HELPER FUNCTION
int min(int a, int b) => a < b ? a : b;
