import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/mess/presentation/pages/create_join_mess_page.dart';
import '../../features/mess/presentation/pages/pending_approval_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/setup/setup_page.dart';
import '../../features/admin/admin_shell.dart';

class AppRouter {
  static const String login = '/';
  static const String otpVerification = '/otp-verification';
  static const String createJoinMess = '/create-join-mess';
  static const String pendingApproval = '/pending-approval';
  static const String dashboard = '/dashboard';
  static const String setup = '/setup';
  static const String admin = '/admin';

  static final GoRouter router = GoRouter(
    initialLocation: dashboard,
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final loc = state.matchedLocation;

      // Always allow OTP verification through
      if (loc == otpVerification) return null;

      // Not logged in → login
      if (user == null) {
        if (loc == login) return null;
        return login;
      }

      // Check joinStatus for logged-in users going to dashboard
      if (loc == dashboard) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final joinStatus = userDoc.data()?['joinStatus'] as String? ?? '';
          if (joinStatus == 'pending') return pendingApproval;
        } catch (_) {}
      }

      return null;
    },
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginPage()),
      GoRoute(
        path: otpVerification,
        builder: (context, state) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: createJoinMess,
        builder: (context, state) => const CreateJoinMessPage(),
      ),
      GoRoute(
        path: pendingApproval,
        builder: (context, state) => const PendingApprovalPage(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(path: setup, builder: (context, state) => const SetupPage()),
      GoRoute(
        path: admin,
        builder: (context, state) => const AdminShell(),
        redirect: (context, state) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return login;
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final role = doc.data()?['role'] as String? ?? 'member';
          final isAdmin =
              role == 'manager' ||
              role == 'superAdmin' ||
              role == 'systemAdmin' ||
              role == 'supportAdmin' ||
              role == 'contentAdmin';
          if (!isAdmin) return dashboard;
          return null;
        },
      ),
    ],
  );
}
