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
  String _status = 'Not connected';
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
        _status = 'Connected with Google';
        _userId = MediaGoogle.getCurrentUserId();
        _email = MediaGoogle.getCurrentUserEmail();
      });
    }
  }

  Future<void> _handleGoogleSignUp({bool selectAccount = false}) async {
    setState(() => _isLoading = true);
    try {
      // optionally clear local session first (not required)
      // await MediaGoogle.signOutGoogle();

      await MediaGoogle.signUpWithGoogle(selectAccount: selectAccount);
      // Sync user profile after successful login
      await MediaRepository.syncUserProfile();
      await _checkLoginStatus();
      // Navigate to app after successful login
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
        _status = 'Not connected';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Google Connect')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (_email != null) ...[
                      Text('Email: $_email'),
                      const SizedBox(height: 8),
                    ],
                    if (_userId != null) ...[
                      Text('User ID: $_userId'),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (_userId == null)
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleGoogleSignUp(selectAccount: true),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Connect with Google'),
                )
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Sign Out'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignUp,
                      icon: const Icon(Icons.add),
                      label: _isLoading
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Connect with Another Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}