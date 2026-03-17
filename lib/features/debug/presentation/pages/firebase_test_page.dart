import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firebase_mess_service.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final _testResults = <String>[];
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('Firebase Integration Test'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isTesting ? null : _runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isTesting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Run Firebase Tests'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                final isSuccess = result.startsWith('✅');
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isSuccess ? Icons.check_circle : Icons.error,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      result,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSuccess ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    await _testFirebaseConnection();
    await _testAuthentication();
    await _testFirestore();
    await _testMessOperations();

    setState(() => _isTesting = false);
  }

  Future<void> _testFirebaseConnection() async {
    _addResult('🔍 Testing Firebase Connection...');
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final user = FirebaseAuthService.currentUser;
      _addResult('✅ Firebase initialized successfully');
      _addResult('✅ Current user: ${user?.email ?? "Not logged in"}');
    } catch (e) {
      _addResult('❌ Firebase connection failed: $e');
    }
  }

  Future<void> _testAuthentication() async {
    _addResult('\n🔍 Testing Authentication...');
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Test registration
      final testEmail = 'test${DateTime.now().millisecondsSinceEpoch}@test.com';
      final registerResult = await FirebaseAuthService.registerUser(
        name: 'Test User',
        mobile: '01700000000',
        email: testEmail,
        password: 'Test@123',
      );

      if (registerResult['success']) {
        _addResult('✅ User registration successful');
        _addResult('✅ User ID: ${registerResult['userId']}');

        // Test login
        await FirebaseAuthService.logout();
        final loginResult = await FirebaseAuthService.loginUser(
          email: testEmail,
          password: 'Test@123',
        );

        if (loginResult['success']) {
          _addResult('✅ User login successful');
        } else {
          _addResult('❌ Login failed: ${loginResult['message']}');
        }

        // Test get user data
        final userData = await FirebaseAuthService.getUserData();
        if (userData != null) {
          _addResult('✅ User data retrieved: ${userData['name']}');
        } else {
          _addResult('❌ Failed to retrieve user data');
        }
      } else {
        _addResult('❌ Registration failed: ${registerResult['message']}');
      }
    } catch (e) {
      _addResult('❌ Authentication test failed: $e');
    }
  }

  Future<void> _testFirestore() async {
    _addResult('\n🔍 Testing Firestore Database...');
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Test update user data
      final updateResult = await FirebaseAuthService.updateUserData({
        'testField': 'Test Value',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (updateResult) {
        _addResult('✅ Firestore write successful');

        // Test read user data
        final userData = await FirebaseAuthService.getUserData();
        if (userData?['testField'] == 'Test Value') {
          _addResult('✅ Firestore read successful');
        } else {
          _addResult('❌ Firestore read failed');
        }
      } else {
        _addResult('❌ Firestore write failed');
      }
    } catch (e) {
      _addResult('❌ Firestore test failed: $e');
    }
  }

  Future<void> _testMessOperations() async {
    _addResult('\n🔍 Testing Mess Operations...');
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Test create mess
      final createResult = await FirebaseMessService.createMess(
        messName: 'Test Mess ${DateTime.now().millisecondsSinceEpoch}',
        address: 'Test Address',
        district: 'Dhaka',
      );

      if (createResult['success']) {
        _addResult('✅ Mess created: ${createResult['messId']}');

        // Test get mess data
        final messData = await FirebaseMessService.getMessData();
        if (messData != null) {
          _addResult('✅ Mess data retrieved: ${messData['name']}');
        } else {
          _addResult('❌ Failed to retrieve mess data');
        }

        // Test is manager
        final isManager = await FirebaseMessService.isManager();
        _addResult('✅ Manager check: $isManager');

        // Test get mess members
        final members = await FirebaseMessService.getMessMembers();
        _addResult('✅ Mess members count: ${members.length}');
      } else {
        _addResult('❌ Mess creation failed: ${createResult['message']}');
      }
    } catch (e) {
      _addResult('❌ Mess operations test failed: $e');
    }
  }

  void _addResult(String result) {
    setState(() => _testResults.add(result));
  }
}
