import 'package:flutter/material.dart';

import '../../Models/Akram/media_google.dart';
import '../../repositories/Akram/media_repository.dart';

class MediaGoogleConnect extends StatefulWidget {
  const MediaGoogleConnect({super.key});

  @override
  State<MediaGoogleConnect> createState() => _MediaGoogleConnectState();
}

class _MediaGoogleConnectState extends State<MediaGoogleConnect> {
  bool _isLoading = false;
  String? _userId;
  String? _email;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await MediaGoogle.isLoggedIn();
    if (isLoggedIn) {
      setState(() {
        _userId = MediaGoogle.getCurrentUserId();
        _email = MediaGoogle.getCurrentUserEmail();
      });
    }
  }

  Future<void> _handleGoogleSignUp({bool selectAccount = false}) async {
    setState(() => _isLoading = true);
    try {
      await MediaGoogle.signUpWithGoogle(selectAccount: selectAccount);
      await MediaRepository.syncUserProfile();
      await _checkLoginStatus();
      if (mounted && _userId != null) {
        Navigator.of(context).pushReplacementNamed('/navBottom');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await MediaGoogle.signOutGoogle();
      setState(() {
        _userId = null;
        _email = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _userId != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google Logo
                Image.network(
                  'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.account_circle,
                      size: 100,
                      color: Colors.grey[300],
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Connected Status
                if (isConnected) ...[
                  Icon(Icons.check_circle,
                    color: Colors.green[700],
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  if (_email != null)
                    Text(
                      _email!,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF4285F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Add Account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleSignOut,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleGoogleSignUp(selectAccount: true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF4285F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}