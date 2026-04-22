import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});
  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  int? _selectedAmount;
  final _customCtrl = TextEditingController();
  bool _isCustom = false;
  String _userName = 'Friend';

  final _packages = [
    {
      'emoji': '☕',
      'amount': 10,
      'title': 'এক কাপ চা',
      'desc': '"শুধুমাত্র এক কাপ চা খাওয়াচ্ছেন!"',
    },
    {
      'emoji': '🍪',
      'amount': 20,
      'title': 'চা + বিস্কুট',
      'desc': '"সুন্দর কম্বিনেশন, চা + বিস্কুট একসাথে খাওয়াচ্ছেন"',
    },
    {
      'emoji': '☕',
      'amount': 30,
      'title': 'কফি',
      'desc': '"বাহ, এক কাপ কফি খাওয়াতে যাচ্ছেন আপনি"',
    },
    {
      'emoji': '🍪',
      'amount': 50,
      'title': 'কফি + বিস্কুট',
      'desc': '"আমি খুবই আনন্দিত যে আপনি কফির সাথে বিস্কুটও দিচ্ছেন"',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      user ??= await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final name = doc.data()?['name'] as String?;
      if (mounted && name != null && name.isNotEmpty) {
        setState(() => _userName = name);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _proceed() {
    final amount = _isCustom
        ? int.tryParse(_customCtrl.text.trim())
        : _selectedAmount;
    if (amount == null || amount <= 0) return;
    _showPaymentSheet(amount);
  }

  void _showPaymentSheet(int amount) {
    final pkg = _isCustom
        ? {
            'emoji': '✍️',
            'desc': '"কি খাওয়াতে চাচ্ছেন লিখুন"',
            'title': 'Custom',
          }
        : _packages.firstWhere(
            (p) => p['amount'] == amount,
            orElse: () => {'emoji': '✍️', 'desc': '', 'title': ''},
          );

    String? selectedMethod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // package summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      pkg['emoji'] as String,
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg['desc'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'BDT $amount',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE91E63),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(height: 10),
              _methodTile(
                setS,
                selectedMethod,
                'bKash',
                '🟣',
                const Color(0xFFE2136E),
                (v) => selectedMethod = v,
              ),
              const SizedBox(height: 8),
              _methodTile(
                setS,
                selectedMethod,
                'Nagad',
                '🔵',
                const Color(0xFFF6821F),
                (v) => selectedMethod = v,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedMethod == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _showThankYou(amount);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'NEXT →',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodTile(
    StateSetter setS,
    String? selected,
    String name,
    String emoji,
    Color color,
    void Function(String) onSelect,
  ) {
    final sel = selected == name;
    return GestureDetector(
      onTap: () => setS(() => onSelect(name)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? color : Colors.grey.shade200,
            width: sel ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: sel ? color : AppColors.textDark,
              ),
            ),
            const Spacer(),
            Icon(
              sel ? Icons.radio_button_checked : Icons.radio_button_off,
              color: sel ? color : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showThankYou(int amount) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('❤️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                "Thank you '$_userName' for\nsupporting Meal Manager ❤️",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You're helping us grow",
                style: TextStyle(color: AppColors.textLight, fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Show Your Love ❤️',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text('☕', style: TextStyle(fontSize: 44)),
                  SizedBox(height: 10),
                  Text(
                    'এক কাপ চা খাওয়াতে চাও? ☕',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'এই Meal Manager অ্যাপটা আমরা ফ্রি রেখেছি সবার জন্য।\nতোমার ছোট্ট চা-সাপোর্ট আমাদের আরও ভালো ফিচার বানাতে অনুপ্রাণিত করবে 💪',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '☕ Support Packages',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ...(_packages.map((p) => _packageCard(p))),
            const SizedBox(height: 8),
            _customCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_selectedAmount != null ||
                        (_isCustom && _customCtrl.text.isNotEmpty))
                    ? _proceed
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Support Now ❤️',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _packageCard(Map<String, dynamic> pkg) {
    final isSelected = !_isCustom && _selectedAmount == pkg['amount'];
    return GestureDetector(
      onTap: () => setState(() {
        _selectedAmount = pkg['amount'] as int;
        _isCustom = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFE91E63) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(pkg['emoji'] as String, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BDT ${pkg['amount']} — ${pkg['title']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pkg['desc'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? const Color(0xFFE91E63)
                  : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _customCard() {
    return GestureDetector(
      onTap: () => setState(() {
        _isCustom = true;
        _selectedAmount = null;
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isCustom ? const Color(0xFFE91E63) : Colors.grey.shade200,
            width: _isCustom ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('✍️', style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Text(
                  'Custom Amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            if (_isCustom) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'কি খাওয়াতে চাচ্ছেন লিখুন (amount in BDT)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFE91E63),
                      width: 2,
                    ),
                  ),
                  prefixText: 'BDT ',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
