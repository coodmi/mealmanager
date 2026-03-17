import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';

/// One-time setup page: creates "Alpha Mess" in Firestore and links it
/// to the currently logged-in user as manager.
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String _status = '';
  bool _running = false;
  bool _done = false;

  Future<void> _setup() async {
    setState(() {
      _running = true;
      _status = 'Waiting for auth...';
    });

    try {
      // Wait for auth
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );
      }

      if (user == null) {
        setState(() {
          _status = '❌ Not logged in. Please login first.';
          _running = false;
        });
        return;
      }

      setState(
        () => _status =
            '✅ User: ${user!.email}\nUID: ${user.uid}\n\nCreating mess...',
      );

      const messId = 'MM_ALPHA';
      final firestore = FirebaseFirestore.instance;

      // Create the mess document
      await firestore.collection('messes').doc(messId).set({
        'name': 'Alpha Mess',
        'address': 'Dhaka',
        'district': 'Dhaka',
        'managerId': user.uid,
        'members': [user.uid],
        'balance': 5430,
        'subscription': 'free',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _status += '\n✅ Mess created: Alpha Mess (ID: $messId)');

      // Update user document
      await firestore.collection('users').doc(user.uid).set({
        'name': 'Admin',
        'email': user.email ?? '',
        'mobile': '',
        'messId': messId,
        'role': 'manager',
        'balance': 1250,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _status += '\n✅ User linked to Alpha Mess as manager');
      setState(() {
        _status += '\n\n🎉 Setup complete! Tap "Go to Dashboard" to continue.';
        _running = false;
        _done = true;
      });
    } catch (e) {
      setState(() {
        _status += '\n❌ Error: $e';
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('Database Setup'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will create:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Mess: "Alpha Mess" (ID: MM_ALPHA)'),
                  const Text('• Link current user as Manager'),
                  const Text('• Set balance data'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (!_done)
              ElevatedButton(
                onPressed: _running ? null : _setup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _running
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Run Setup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            if (_done) ...[
              ElevatedButton(
                onPressed: () => context.go(AppRouter.dashboard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go to Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
