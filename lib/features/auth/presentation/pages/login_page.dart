import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/email_service.dart';
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

  // ── REGISTER: Send OTP first ──────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final email = _registerEmailController.text.trim();
    final name = _registerNameController.text.trim();
    final result = await EmailService.sendOTPEmail(email: email, name: name);
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      _showOtpDialog(
        email: email,
        name: name,
        mobile: _registerMobileController.text.trim(),
        password: _registerPasswordController.text,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to send OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── OTP DIALOG ────────────────────────────────────────────────────────────
  void _showOtpDialog({
    required String email,
    required String name,
    required String mobile,
    required String password,
  }) {
    final controllers = List.generate(6, (_) => TextEditingController());
    final focusNodes = List.generate(6, (_) => FocusNode());
    bool isVerifying = false;
    bool isResending = false;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          String getOtp() => controllers.map((c) => c.text).join();

          Future<void> doVerify() async {
            final otp = getOtp();
            if (otp.length < 6) {
              setS(() => errorMsg = 'Please enter all 6 digits');
              return;
            }
            setS(() {
              isVerifying = true;
              errorMsg = null;
            });

            final vr = await EmailService.verifyOTP(
              email: email,
              enteredOtp: otp,
            );
            if (vr['success'] != true) {
              setS(() {
                isVerifying = false;
                errorMsg = vr['message'];
              });
              return;
            }

            final rr = await FirebaseAuthService.registerUser(
              name: name,
              mobile: mobile,
              email: email,
              password: password,
            );
            setS(() => isVerifying = false);

            if (rr['success'] == true) {
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                _registerNameController.clear();
                _registerMobileController.clear();
                _registerEmailController.clear();
                _registerPasswordController.clear();
                _tabController.animateTo(0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account created! Please login.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } else {
              setS(() => errorMsg = rr['message'] ?? 'Registration failed');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_rounded,
                    color: AppColors.primaryGreen,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Enter OTP',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'We sent a 6-digit code to',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valid for 10 minutes',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (i) => SizedBox(
                      width: 42,
                      height: 50,
                      child: TextField(
                        controller: controllers[i],
                        focusNode: focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (val) {
                          setS(() => errorMsg = null);
                          if (val.isNotEmpty && i < 5) {
                            focusNodes[i + 1].requestFocus();
                          } else if (val.isEmpty && i > 0) {
                            focusNodes[i - 1].requestFocus();
                          }
                          if (getOtp().length == 6) {
                            Future.delayed(
                              const Duration(milliseconds: 150),
                              doVerify,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorMsg!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: isResending
                    ? null
                    : () async {
                        setS(() => isResending = true);
                        final r = await EmailService.sendOTPEmail(
                          email: email,
                          name: name,
                        );
                        setS(() {
                          isResending = false;
                          errorMsg = null;
                        });
                        for (final c in controllers) c.clear();
                        focusNodes[0].requestFocus();
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                r['success'] == true
                                    ? 'New OTP sent to $email'
                                    : r['message'] ?? 'Failed',
                              ),
                              backgroundColor: r['success'] == true
                                  ? Colors.green
                                  : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: isResending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(isResending ? 'Sending...' : 'Resend OTP'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isVerifying ? null : doVerify,
                child: isVerifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (focusNodes[0].canRequestFocus) focusNodes[0].requestFocus();
    });
  }

  // ── GOOGLE LOGIN ──────────────────────────────────────────────────────────
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      final result = await AuthService.signInWithGoogle();
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (result['success']) {
        await _navigateAfterLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      final result = await AuthService.loginUser(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (result['success']) {
        await _navigateAfterLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Wrong ID/Password entered'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
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

  Future<void> _navigateAfterLogin() async {
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
      return;
    }
    final messId = userData?['messId'] as String? ?? '';
    if (messId.isNotEmpty) {
      try {
        final messDoc = await FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .get();
        final setupComplete =
            messDoc.data()?['setupComplete'] as bool? ?? false;
        if (!mounted) return;
        context.go(
          setupComplete ? AppRouter.dashboard : AppRouter.messSettings,
        );
      } catch (_) {
        if (mounted) context.go(AppRouter.dashboard);
      }
    } else {
      context.go(AppRouter.createJoinMess);
    }
  }

  // ── FORGOT PASSWORD ───────────────────────────────────────────────────────
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
                'Enter your email and we\'ll send a reset link.',
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
                    borderSide: const BorderSide(
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
                                'Reset link sent to $email — check inbox & spam.',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setS(() => isSending = false);
                        final msg = e.code == 'user-not-found'
                            ? 'No account found with this email'
                            : e.code == 'invalid-email'
                            ? 'Invalid email address'
                            : 'Error (${e.code}): ${e.message}';
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

  // ── BUILD ─────────────────────────────────────────────────────────────────
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

  Widget _inputBox(Widget child) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
    ),
    child: child,
  );

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          _inputBox(
            TextFormField(
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
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 16),
          _inputBox(
            TextFormField(
              controller: _loginPasswordController,
              obscureText: !_loginPasswordVisible,
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
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: AppColors.primaryGreen, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
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
          _orDivider(),
          const SizedBox(height: 16),
          _googleButton('Sign in with Google'),
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
            _inputBox(
              TextFormField(
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
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            _inputBox(
              TextFormField(
                controller: _registerMobileController,
                keyboardType: TextInputType.phone,
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
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (v!.length != 11) return 'Must be 11 digits';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _inputBox(
              TextFormField(
                controller: _registerEmailController,
                keyboardType: TextInputType.emailAddress,
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
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (!v!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _inputBox(
              TextFormField(
                controller: _registerPasswordController,
                obscureText: !_registerPasswordVisible,
                onChanged: (v) => setState(() => _registerPassword = v),
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
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (v!.length < 6) return 'Minimum 6 characters required';
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
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
            _orDivider(),
            const SizedBox(height: 16),
            _googleButton('Sign up with Google'),
          ],
        ),
      ),
    );
  }

  Widget _orDivider() => Row(
    children: [
      Expanded(
        child: Divider(color: AppColors.textLight.withValues(alpha: 0.3)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'or',
          style: TextStyle(color: AppColors.textLight, fontSize: 13),
        ),
      ),
      Expanded(
        child: Divider(color: AppColors.textLight.withValues(alpha: 0.3)),
      ),
    ],
  );

  Widget _googleButton(String label) => SizedBox(
    width: double.infinity,
    height: 56,
    child: OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleLogin,
      icon: Image.network(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
        width: 22,
        height: 22,
        errorBuilder: (_, __, ___) => const Text(
          'G',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
    ),
  );
}

// ── Password Strength Bar ─────────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int get _score {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) s++;
    return s;
  }

  String get _label =>
      ['', 'Weak', 'Fair', 'Good', 'Strong'][_score.clamp(0, 4)];

  Color get _color => [
    Colors.grey,
    Colors.red,
    Colors.orange,
    Colors.lightGreen,
    Colors.green,
  ][_score.clamp(0, 4)];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
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
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      ],
    );
  }
}
