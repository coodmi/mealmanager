import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firebase_auth_service.dart';

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
  bool _loginPasswordVisible = false;
  bool _registerPasswordVisible = false;
  String _registerPassword = '';

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
      final result = await FirebaseAuthService.registerUser(
        name: _registerNameController.text.trim(),
        mobile: _registerMobileController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result['success'] == true) {
        // Show email verification dialog
        _showEmailVerificationDialog(_registerEmailController.text.trim());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEmailVerificationDialog(String email) {
    bool isChecking = false;
    bool isResending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.primaryGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'We sent a verification link to:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Click the link in the email to verify your account, then tap "I\'ve Verified" below.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Check your spam/junk folder if you don\'t see it.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            // Resend button
            TextButton.icon(
              onPressed: isResending
                  ? null
                  : () async {
                      setS(() => isResending = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        await user?.sendEmailVerification();
                        setS(() => isResending = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Verification email resent!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (_) {
                        setS(() => isResending = false);
                      }
                    },
              icon: isResending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(isResending ? 'Sending...' : 'Resend Email'),
            ),
            // Verified button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isChecking
                  ? null
                  : () async {
                      setS(() => isChecking = true);
                      try {
                        // Reload user to get latest emailVerified status
                        final user = FirebaseAuth.instance.currentUser;
                        await user?.reload();
                        final refreshed = FirebaseAuth.instance.currentUser;

                        if (refreshed?.emailVerified == true) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            // Clear form
                            _registerNameController.clear();
                            _registerMobileController.clear();
                            _registerEmailController.clear();
                            _registerPasswordController.clear();
                            _tabController.animateTo(0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Email verified! You can now login.',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          setS(() => isChecking = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Email not verified yet. Please click the link in your email.',
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      } catch (_) {
                        setS(() => isChecking = false);
                      }
                    },
              child: isChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "I've Verified",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
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
                height: 620,
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
            role == 'contentAdmin';
        if (isAdmin) {
          context.go(AppRouter.admin);
        } else if (userData != null &&
            userData['messId'] != null &&
            (userData['messId'] as String).isNotEmpty) {
          // Check mess setup
          final messId = userData['messId'] as String;
          try {
            final messDoc = await FirebaseFirestore.instance
                .collection('messes')
                .doc(messId)
                .get();
            final setupComplete =
                messDoc.data()?['setupComplete'] as bool? ?? false;
            if (!mounted) return;
            if (setupComplete) {
              context.go(AppRouter.dashboard);
            } else {
              context.go(AppRouter.messSettings);
            }
          } catch (_) {
            if (mounted) context.go(AppRouter.dashboard);
          }
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
            role == 'contentAdmin';

        if (isAdmin) {
          context.go(AppRouter.admin);
        } else if (userData != null &&
            userData['messId'] != null &&
            (userData['messId'] as String).isNotEmpty) {
          // Check if mess setup is complete
          final messId = userData['messId'] as String;
          try {
            final messDoc = await FirebaseFirestore.instance
                .collection('messes')
                .doc(messId)
                .get();
            final setupComplete =
                messDoc.data()?['setupComplete'] as bool? ?? false;
            if (!mounted) return;
            if (setupComplete) {
              context.go(AppRouter.dashboard);
            } else {
              context.go(AppRouter.messSettings);
            }
          } catch (_) {
            if (mounted) context.go(AppRouter.dashboard);
          }
        } else {
          context.go(AppRouter.createJoinMess);
        }
      } else {
        // Check if needs email verification
        if (result['needsVerification'] == true) {
          _showEmailVerificationDialog(_loginEmailController.text.trim());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong ID/Password entered'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(
      text: _loginEmailController.text.trim(),
    );
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isSending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid email'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      setS(() => isSending = true);
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: email,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reset link sent to $email — check inbox & spam folder.',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setS(() => isSending = false);
                        String msg;
                        switch (e.code) {
                          case 'user-not-found':
                            msg = 'No account found with this email';
                            break;
                          case 'invalid-email':
                            msg = 'Invalid email address';
                            break;
                          case 'too-many-requests':
                            msg = 'Too many attempts. Try again later';
                            break;
                          default:
                            msg =
                                'Error (${e.code}): ${e.message ?? 'Failed to send'}';
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        }
                      } catch (e) {
                        setS(() => isSending = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        }
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send Link',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
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
                suffixIcon: IconButton(
                  icon: Icon(
                    _loginPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () => setState(
                    () => _loginPasswordVisible = !_loginPasswordVisible,
                  ),
                ),
              ),
              obscureText: !_loginPasswordVisible,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(),
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
                  hintText: 'Password (min 6 characters)',
                  hintStyle: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: false,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _registerPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () =>
                          _registerPasswordVisible = !_registerPasswordVisible,
                    ),
                  ),
                ),
                obscureText: !_registerPasswordVisible,
                onChanged: (v) => setState(() => _registerPassword = v),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 6) return 'Minimum 6 characters required';
                  return null;
                },
              ),
            ),
            if (_registerPassword.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PasswordStrengthBar(password: _registerPassword),
            ],
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
                  'Sign up with Google',
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
      ),
    );
  }
}

// ── Password Strength Indicator ──────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  // Returns 0-4 score
  int get _score {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) s++;
    return s;
  }

  String get _label {
    switch (_score) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  Color get _color {
    switch (_score) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.lightGreen;
      default:
        return Colors.green;
    }
  }

  String get _suggestion {
    final tips = <String>[];
    if (password.length < 8) tips.add('8+ characters');
    if (!password.contains(RegExp(r'[A-Z]'))) tips.add('uppercase letter');
    if (!password.contains(RegExp(r'[0-9]'))) tips.add('a number');
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]')))
      tips.add('a symbol (!@#...)');
    if (tips.isEmpty) return 'Great password!';
    return 'Add: ${tips.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i < _score
                      ? _color
                      : Colors.grey.withValues(alpha: 0.25),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
            Flexible(
              child: Text(
                _suggestion,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
