import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/Akram/media_google.dart';
import '../../repositories/Akram/media_repository.dart';
import '../../viewmodels/maamoune/user_viewmodel.dart';

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
    try {
      final isLoggedIn = await MediaGoogle.isLoggedIn();
      if (isLoggedIn) {
        setState(() {
          _userId = MediaGoogle.getCurrentUserId();
          _email = MediaGoogle.getCurrentUserEmail();
        });

        // Also sync to database on init
        if (mounted && _userId != null) {
          await context.read<UserViewModel>().syncGoogleUser();
        }
      }
    } catch (e) {
      print('❌ Error checking login status: $e');
    }
  }

  Future<void> _handleGoogleSignUp({bool selectAccount = false}) async {
    setState(() => _isLoading = true);
    try {
      print('🔐 Starting Google sign-up...');

      // Step 1: Sign up with Google
      await MediaGoogle.signUpWithGoogle(selectAccount: selectAccount);
      print('✅ Google sign-up completed');

      // Step 2: Get the new auth user
      final authUser = MediaGoogle.getCurrentUserId();
      if (authUser == null) {
        throw Exception('Failed to get user ID from Google');
      }
      print('👤 Got user ID: $authUser');

      // Step 3: Sync to Supabase database
      if (mounted) {
        print('🔄 Syncing user to Supabase...');
        final userViewModel = context.read<UserViewModel>();
        final syncedUser = await userViewModel.syncGoogleUser();

        if (syncedUser == null) {
          throw Exception('Failed to sync user to database');
        }
        print('✅ User synced successfully: ${syncedUser.id}');
      }

      // Step 4: Load media profile
      print('📥 Loading media profile...');
      await MediaRepository.syncUserProfile();
      print('✅ Media profile loaded');

      // Step 5: Update UI
      await _checkLoginStatus();

      if (mounted && _userId != null) {
        print('🚀 Navigating to home...');
        Navigator.of(context).pushReplacementNamed('/navBottom');
      }
    } catch (e) {
      print('❌ Error during sign up: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      print('👋 Starting sign out...');

      // Step 1: Sign out from Google
      await MediaGoogle.signOutGoogle();
      print('✅ Signed out from Google');

      // Step 2: Sign out from Supabase and clear data
      if (mounted) {
        await context.read<UserViewModel>().signOut();
        print('✅ Signed out from Supabase');
      }

      setState(() {
        _userId = null;
        _email = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error during sign out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _userId != null && _email != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
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
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.email, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _email!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _userId!.substring(0, 12) + '...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[600],
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleGoogleSignUp(selectAccount: true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF4285F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                          'Add Another Account',
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                            : const Text(
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
                    Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connect your Google account to access the app',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleGoogleSignUp(selectAccount: true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF4285F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }
}
