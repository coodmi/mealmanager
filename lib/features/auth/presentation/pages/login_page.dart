import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerMobileController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerMobileController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.registerUser(
        name: _registerNameController.text.trim(),
        mobile: _registerMobileController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        // Show OTP in dialog for easy testing
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('OTP Sent!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OTP sent to ${_registerEmailController.text}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryGreen),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your OTP Code:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result['otp'] ?? 'Check console',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                          letterSpacing: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Demo Mode: OTP shown here for testing',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRouter.otpVerification);
                },
                child: const Text(
                  'Continue to Verification',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Image.asset(
                'assets/images/logo.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.slogan,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryGreen,
                  unselectedLabelColor: AppColors.textLight,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Register'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 520,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildLoginForm(), _buildRegisterForm()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      final result = await AuthService.signInWithGoogle();
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (result['success']) {
        final userData = await AuthService.getUserData();
        if (!mounted) return;
        final role = userData?['role'] as String? ?? 'member';
        final isAdmin =
            role == 'superAdmin' ||
            role == 'systemAdmin' ||
            role == 'supportAdmin' ||
            role == 'contentAdmin' ||
            role == 'manager';
        if (isAdmin) {
          context.go(AppRouter.admin);
        } else if (userData != null && userData['messId'] != null) {
          context.go(AppRouter.dashboard);
        } else {
          context.go(AppRouter.createJoinMess);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Always sign out any existing session before logging in a new user.
      // This prevents stale sessions (e.g. super admin) from persisting
      // when a different user tries to log in.
      await FirebaseAuth.instance.signOut();

      final result = await AuthService.loginUser(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        // Get user data to check role and mess
        final userData = await AuthService.getUserData();

        if (!mounted) return;

        final role = userData?['role'] as String? ?? 'member';
        final isAdmin =
            role == 'superAdmin' ||
            role == 'systemAdmin' ||
            role == 'supportAdmin' ||
            role == 'contentAdmin' ||
            role == 'manager';

        if (isAdmin) {
          // Admin users go directly to admin panel
          context.go(AppRouter.admin);
        } else if (userData != null && userData['messId'] != null) {
          // User has a mess, go directly to dashboard
          context.go(AppRouter.dashboard);
        } else {
          // User doesn't have a mess, go to create/join mess page
          context.go(AppRouter.createJoinMess);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: TextFormField(
              controller: _loginEmailController,
              decoration: InputDecoration(
                hintText: 'Mobile/Email',
                hintStyle: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                filled: false,
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: TextFormField(
              controller: _loginPasswordController,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                filled: false,
              ),
              obscureText: true,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: AppColors.primaryGreen, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonGreen,
                disabledBackgroundColor: AppColors.buttonGreen.withValues(
                  alpha: 0.6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.textLight.withValues(alpha: 0.3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.textLight.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleGoogleLogin,
              icon: Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.g_mobiledata, size: 22),
              ),
              label: const Text(
                'Sign in with Google',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(
                  color: AppColors.primaryGreen.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: TextFormField(
                controller: _registerNameController,
                decoration: InputDecoration(
                  hintText: 'Your Name',
                  hintStyle: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: false,
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: TextFormField(
                controller: _registerMobileController,
                decoration: InputDecoration(
                  hintText: 'Mobile number (017xxx)',
                  hintStyle: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: false,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length != 11) return 'Must be 11 digits';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: TextFormField(
                controller: _registerEmailController,
                decoration: InputDecoration(
                  hintText: 'Email Address',
                  hintStyle: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: false,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: TextFormField(
                controller: _registerPasswordController,
                decoration: InputDecoration(
                  hintText: 'Password (3-10 characters)',
                  hintStyle: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: false,
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 3 || value.length > 10) {
                    return '3-10 characters required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonGreen,
                  disabledBackgroundColor: AppColors.buttonGreen.withValues(
                    alpha: 0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
