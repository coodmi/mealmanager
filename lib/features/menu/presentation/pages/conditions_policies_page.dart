import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ConditionsPoliciesPage extends StatefulWidget {
  const ConditionsPoliciesPage({super.key});

  @override
  State<ConditionsPoliciesPage> createState() => _ConditionsPoliciesPageState();
}

class _ConditionsPoliciesPageState extends State<ConditionsPoliciesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBangla = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Conditions & Policies',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _isBangla = !_isBangla),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white54),
                ),
                child: Text(
                  _isBangla ? 'EN' : 'বাং',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Terms & Conditions'),
            Tab(text: 'Privacy Policy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TermsContent(isBangla: _isBangla),
          _PrivacyContent(isBangla: _isBangla),
        ],
      ),
    );
  }
}

// ─── Terms Content ────────────────────────────────────────────────────────────
class _TermsContent extends StatelessWidget {
  final bool isBangla;
  const _TermsContent({required this.isBangla});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isBangla ? _banglaTerms() : _englishTerms(),
      ),
    );
  }

  List<Widget> _englishTerms() => [
    _header('📜 Terms & Conditions – Meal Manager'),
    _sub(
      'Welcome to Meal Manager. By using Meal Manager, you agree to the following terms:',
    ),
    const SizedBox(height: 16),
    _section('1. Use of Service', [
      'You must provide accurate information.',
      'You are responsible for maintaining your account\'s data.',
      'Misuse of the app may result in suspension.',
    ]),
    _section('2. Mess Data Responsibility', [
      'All mess data is managed by the users (Manager & Members).',
      'Meal Manager is not responsible for incorrect entries or calculations caused by user input.',
    ]),
    _section('3. Data Deletion Policy ⚠️', [
      'Running mess data will be stored for a maximum of 6 months.',
      'After 6 months, data will be automatically deleted from the server.',
      'Inactive messes will be automatically deleted after 6 months of inactivity.',
      'All Notifications (Mess requests, My requests, Home top notifications) & chat messages: 40 days.',
      'FYI, Transactions pages, Memberwise personal Meal & Transaction history will not be deleted after 40 days — they will be deleted after 6 months as per Mess data deletion policy.',
    ]),
    _section('4. Data Recovery Policy', [
      'If a mess is deleted by the Manager, users may contact support.',
      'Data can be recovered within 30 days only after deletion.',
      'After 30 days, data recovery is not possible.',
    ]),
    _section('5. Data Reset Request', [
      'If a mess wants to reset all data (e.g. new start) or specific month\'s data, Meal Manager team may assist upon request.',
    ]),
    _section('6. Payments & Subscription', [
      'Premium features require valid subscription.',
      'Payments once completed are non-refundable.',
      'Subscription validity is month based. If you start a premium package, it will expire on the last date of the month.',
    ]),
    _section('7. Service Availability', [
      'We strive to keep the app running smoothly.',
      'However, temporary downtime or maintenance may occur.',
    ]),
    _section('8. Limitation of Liability', [
      'Meal Manager is not liable for:',
      '• Data loss due to user action.',
      '• Incorrect financial calculations due to wrong input.',
      '• Service interruptions.',
    ]),
    _section('9. Changes to Terms', [
      'Terms may be updated at any time.',
      'Continued use of the app means acceptance of updated terms.',
    ]),
  ];

  List<Widget> _banglaTerms() => [
    _header('📜 শর্তাবলী – মিল ম্যানেজার'),
    _sub('মিল ম্যানেজার ব্যবহার করে আপনি নিচের শর্তগুলোতে সম্মত হচ্ছেন:'),
    const SizedBox(height: 16),
    _section('১. সেবার ব্যবহার', [
      'আপনাকে সঠিক তথ্য প্রদান করতে হবে।',
      'আপনার অ্যাকাউন্টের ডেটা রক্ষণাবেক্ষণের দায়িত্ব আপনার।',
      'অ্যাপের অপব্যবহারের ফলে অ্যাকাউন্ট স্থগিত হতে পারে।',
    ]),
    _section('২. মেস ডেটার দায়িত্ব', [
      'সকল মেস ডেটা ব্যবহারকারীরা (ম্যানেজার ও সদস্যরা) পরিচালনা করেন।',
      'ব্যবহারকারীর ভুল ইনপুটের কারণে ভুল হিসাব বা এন্ট্রির জন্য মিল ম্যানেজার দায়ী নয়।',
    ]),
    _section('৩. ডেটা মুছে ফেলার নীতি ⚠️', [
      'চলমান মেস ডেটা সর্বোচ্চ ৬ মাস সংরক্ষিত থাকবে।',
      '৬ মাস পর ডেটা স্বয়ংক্রিয়ভাবে সার্ভার থেকে মুছে যাবে।',
      '৬ মাস নিষ্ক্রিয় থাকলে মেস স্বয়ংক্রিয়ভাবে মুছে যাবে।',
      'সকল নোটিফিকেশন (মেস রিকোয়েস্ট, আমার রিকোয়েস্ট, হোম নোটিফিকেশন) ও চ্যাট মেসেজ: ৪০ দিন।',
      'লেনদেন পাতা, সদস্যভিত্তিক মিল ও লেনদেনের ইতিহাস ৪০ দিনে মুছবে না — মেস ডেটা নীতি অনুযায়ী ৬ মাস পর মুছবে।',
    ]),
    _section('৪. ডেটা পুনরুদ্ধার নীতি', [
      'ম্যানেজার মেস মুছে ফেললে ব্যবহারকারীরা সাপোর্টে যোগাযোগ করতে পারবেন।',
      'মুছে ফেলার ৩০ দিনের মধ্যে ডেটা পুনরুদ্ধার সম্ভব।',
      '৩০ দিন পর ডেটা পুনরুদ্ধার সম্ভব নয়।',
    ]),
    _section('৫. ডেটা রিসেট অনুরোধ', [
      'কোনো মেস সব ডেটা রিসেট করতে চাইলে (যেমন নতুন শুরু) বা নির্দিষ্ট মাসের ডেটা রিসেট করতে চাইলে মিল ম্যানেজার টিম অনুরোধের ভিত্তিতে সহায়তা করতে পারে।',
    ]),
    _section('৬. পেমেন্ট ও সাবস্ক্রিপশন', [
      'প্রিমিয়াম ফিচার ব্যবহারের জন্য বৈধ সাবস্ক্রিপশন প্রয়োজন।',
      'পেমেন্ট সম্পন্ন হলে তা ফেরতযোগ্য নয়।',
      'সাবস্ক্রিপশন মাসভিত্তিক। প্রিমিয়াম প্যাকেজ শুরু করলে মাসের শেষ তারিখে মেয়াদ শেষ হবে।',
    ]),
    _section('৭. সেবার প্রাপ্যতা', [
      'আমরা অ্যাপ সুচারুভাবে চালু রাখার চেষ্টা করি।',
      'তবে সাময়িক বিভ্রাট বা রক্ষণাবেক্ষণ হতে পারে।',
    ]),
    _section('৮. দায়বদ্ধতার সীমা', [
      'মিল ম্যানেজার নিচের বিষয়ে দায়ী নয়:',
      '• ব্যবহারকারীর কারণে ডেটা হারানো।',
      '• ভুল ইনপুটের কারণে ভুল আর্থিক হিসাব।',
      '• সেবা বিঘ্নিত হওয়া।',
    ]),
    _section('৯. শর্তাবলীর পরিবর্তন', [
      'যেকোনো সময় শর্তাবলী আপডেট হতে পারে।',
      'অ্যাপ ব্যবহার অব্যাহত রাখা মানে আপডেট শর্তাবলীতে সম্মতি।',
    ]),
  ];

  Widget _header(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textDark,
    ),
  );

  Widget _sub(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
    ),
  );

  Widget _section(String title, List<String> points) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 6),
        ...points.map(
          (p) => Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!p.startsWith('•'))
                  const Text(
                    '• ',
                    style: TextStyle(fontSize: 14, color: AppColors.textDark),
                  ),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Privacy Content ──────────────────────────────────────────────────────────
class _PrivacyContent extends StatelessWidget {
  final bool isBangla;
  const _PrivacyContent({required this.isBangla});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isBangla ? _banglaPrivacy() : _englishPrivacy(),
      ),
    );
  }

  List<Widget> _englishPrivacy() => [
    _header('📄 Privacy Policy – Meal Manager'),
    _sub(
      'Your privacy is important to us. This Privacy Policy explains how we collect, use and protect your information.',
    ),
    const SizedBox(height: 16),
    _section('1. Information We Collect', [
      'We may collect the following information:',
      '• Name',
      '• Email Address',
      '• Mobile Number',
      '• Blood Group',
      '• Mess-related data (members, meals, expenses, deposits).',
      '• Device information (basic, for security and performance).',
    ]),
    _section('2. How We Use Your Information', [
      'We can use your data to:',
      '• Provide and manage app features.',
      '• Calculate meals, expenses and balances.',
      '• Improve user experience.',
      '• Send notifications (important updates, reminders).',
      '• Marketing purposes.',
      '• Ensure security and prevent misuse.',
    ]),
    _section('3. Data Storage & Security', [
      'Your data is securely stored using trusted cloud services.',
      'We take reasonable measures to protect your data from unauthorized access.',
    ]),
    _section('4. Data Sharing', [
      'We do not sell or share your personal data with third parties, except:',
      '• When required by law.',
      '• For essential services (e.g., payment gateways).',
    ]),
    _section('5. Data Retention', [
      'Active mess data is stored for operational use.',
      'Some data may be automatically deleted as per system rules (see Terms & Conditions).',
    ]),
    _section('6. Your Rights', [
      'You may:',
      '• Update your profile information.',
      '• Request account or data deletion.',
      '• Contact us for support.',
    ]),
    _section('7. Changes to Policy', [
      'We may update this Privacy Policy.',
      'Continued use of the app means acceptance of updated policy.',
    ]),
    _section('8. Contact Us', ['For any questions, contact us.']),
  ];

  List<Widget> _banglaPrivacy() => [
    _header('📄 গোপনীয়তা নীতি – মিল ম্যানেজার'),
    _sub(
      'আপনার গোপনীয়তা আমাদের কাছে গুরুত্বপূর্ণ। এই নীতিতে আমরা কীভাবে তথ্য সংগ্রহ, ব্যবহার ও সুরক্ষা করি তা ব্যাখ্যা করা হয়েছে।',
    ),
    const SizedBox(height: 16),
    _section('১. আমরা যে তথ্য সংগ্রহ করি', [
      'আমরা নিচের তথ্য সংগ্রহ করতে পারি:',
      '• নাম',
      '• ইমেইল ঠিকানা',
      '• মোবাইল নম্বর',
      '• রক্তের গ্রুপ',
      '• মেস সংক্রান্ত ডেটা (সদস্য, মিল, খরচ, জমা)।',
      '• ডিভাইস তথ্য (নিরাপত্তা ও পারফরম্যান্সের জন্য)।',
    ]),
    _section('২. তথ্য ব্যবহারের উদ্দেশ্য', [
      'আমরা আপনার ডেটা ব্যবহার করতে পারি:',
      '• অ্যাপের ফিচার পরিচালনার জন্য।',
      '• মিল, খরচ ও ব্যালেন্স হিসাবের জন্য।',
      '• ব্যবহারকারীর অভিজ্ঞতা উন্নত করতে।',
      '• নোটিফিকেশন পাঠাতে (গুরুত্বপূর্ণ আপডেট, রিমাইন্ডার)।',
      '• মার্কেটিং উদ্দেশ্যে।',
      '• নিরাপত্তা নিশ্চিত করতে ও অপব্যবহার রোধ করতে।',
    ]),
    _section('৩. ডেটা সংরক্ষণ ও নিরাপত্তা', [
      'আপনার ডেটা বিশ্বস্ত ক্লাউড সেবায় নিরাপদে সংরক্ষিত।',
      'অননুমোদিত প্রবেশ থেকে ডেটা রক্ষায় আমরা যুক্তিসঙ্গত ব্যবস্থা নিই।',
    ]),
    _section('৪. ডেটা শেয়ারিং', [
      'আমরা তৃতীয় পক্ষের সাথে আপনার ব্যক্তিগত ডেটা বিক্রি বা শেয়ার করি না, তবে:',
      '• আইনি প্রয়োজনে।',
      '• প্রয়োজনীয় সেবার জন্য (যেমন পেমেন্ট গেটওয়ে)।',
    ]),
    _section('৫. ডেটা সংরক্ষণকাল', [
      'সক্রিয় মেস ডেটা পরিচালনার জন্য সংরক্ষিত থাকে।',
      'কিছু ডেটা সিস্টেম নিয়ম অনুযায়ী স্বয়ংক্রিয়ভাবে মুছে যেতে পারে (শর্তাবলী দেখুন)।',
    ]),
    _section('৬. আপনার অধিকার', [
      'আপনি পারবেন:',
      '• প্রোফাইল তথ্য আপডেট করতে।',
      '• অ্যাকাউন্ট বা ডেটা মুছে ফেলার অনুরোধ করতে।',
      '• সাপোর্টের জন্য যোগাযোগ করতে।',
    ]),
    _section('৭. নীতির পরিবর্তন', [
      'আমরা এই গোপনীয়তা নীতি আপডেট করতে পারি।',
      'অ্যাপ ব্যবহার অব্যাহত রাখা মানে আপডেট নীতিতে সম্মতি।',
    ]),
    _section('৮. যোগাযোগ', ['যেকোনো প্রশ্নের জন্য আমাদের সাথে যোগাযোগ করুন।']),
  ];

  Widget _header(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textDark,
    ),
  );

  Widget _sub(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
    ),
  );

  Widget _section(String title, List<String> points) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 6),
        ...points.map(
          (p) => Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!p.startsWith('•') && !p.endsWith(':'))
                  const Text(
                    '• ',
                    style: TextStyle(fontSize: 14, color: AppColors.textDark),
                  ),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
