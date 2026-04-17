import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});
  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Pre-filled (locked)
  String _name = '';
  String _email = '';
  String _mobile = '';

  // Editable
  final _mobileCtrl = TextEditingController();
  String? _gender;
  String? _profession;
  String? _bloodGroup;
  DateTime? _dob;
  String? _division;
  String? _district;
  String? _thana;

  bool _isGoogleUser = false;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _professions = ['Student', 'Job Holder', 'Business', 'Other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
    'Unknown',
  ];

  static const Map<String, List<String>> _divisionDistricts = {
    'Barisal': [
      'Barguna',
      'Barisal',
      'Bhola',
      'Jhalokati',
      'Patuakhali',
      'Pirojpur',
    ],
    'Chittagong': [
      'Bandarban',
      'Brahmanbaria',
      'Chandpur',
      'Chattogram',
      "Cox's Bazar",
      'Cumilla',
      'Feni',
      'Khagrachhari',
      'Lakshmipur',
      'Noakhali',
      'Rangamati',
    ],
    'Dhaka': [
      'Dhaka',
      'Faridpur',
      'Gazipur',
      'Gopalganj',
      'Kishoreganj',
      'Madaripur',
      'Manikganj',
      'Munshiganj',
      'Narayanganj',
      'Narsingdi',
      'Rajbari',
      'Shariatpur',
      'Tangail',
    ],
    'Khulna': [
      'Bagerhat',
      'Chuadanga',
      'Jessore',
      'Jhenaidah',
      'Khulna',
      'Kushtia',
      'Magura',
      'Meherpur',
      'Narail',
      'Satkhira',
    ],
    'Mymensingh': ['Jamalpur', 'Mymensingh', 'Netrokona', 'Sherpur'],
    'Rajshahi': [
      'Bogura',
      'Chapainawabganj',
      'Joypurhat',
      'Naogaon',
      'Natore',
      'Pabna',
      'Rajshahi',
      'Sirajganj',
    ],
    'Rangpur': [
      'Dinajpur',
      'Gaibandha',
      'Kurigram',
      'Lalmonirhat',
      'Nilphamari',
      'Panchagarh',
      'Rangpur',
      'Thakurgaon',
    ],
    'Sylhet': ['Habiganj', 'Moulvibazar', 'Sunamganj', 'Sylhet'],
  };

  // Simplified thana list per district (top thanas)
  static const Map<String, List<String>> _districtThanas = {
    'Dhaka': [
      'Dhanmondi',
      'Gulshan',
      'Mirpur',
      'Mohammadpur',
      'Motijheel',
      'Pallabi',
      'Ramna',
      'Sabujbagh',
      'Tejgaon',
      'Uttara',
    ],
    'Chattogram': [
      'Agrabad',
      'Bayazid',
      'Chandgaon',
      'Double Mooring',
      'Halishahar',
      'Khulshi',
      'Kotwali',
      'Pahartali',
      'Panchlaish',
      'Patenga',
    ],
    'Gazipur': [
      'Gazipur Sadar',
      'Kaliakair',
      'Kaliganj',
      'Kapasia',
      'Sreepur',
      'Tongi',
    ],
    'Narayanganj': [
      'Araihazar',
      'Bandar',
      'Narayanganj Sadar',
      'Rupganj',
      'Sonargaon',
    ],
    'Sylhet': [
      'Balaganj',
      'Beanibazar',
      'Bishwanath',
      'Companiganj',
      'Fenchuganj',
      'Golapganj',
      'Gowainghat',
      'Jaintiapur',
      'Kanaighat',
      'Sylhet Sadar',
    ],
    'Rajshahi': [
      'Bagha',
      'Bagmara',
      'Charghat',
      'Durgapur',
      'Godagari',
      'Mohanpur',
      'Paba',
      'Puthia',
      'Rajshahi Sadar',
      'Tanore',
    ],
    'Khulna': [
      'Batiaghata',
      'Dacope',
      'Daulatpur',
      'Dighalia',
      'Dumuria',
      'Koyra',
      'Paikgachha',
      'Phultala',
      'Rupsa',
      'Terokhada',
    ],
    'Barisal': [
      'Agailjhara',
      'Babuganj',
      'Bakerganj',
      'Banaripara',
      'Barisal Sadar',
      'Gaurnadi',
      'Hizla',
      'Mehendiganj',
      'Muladi',
      'Wazirpur',
    ],
  };

  List<String> get _districts =>
      _division != null ? (_divisionDistricts[_division] ?? []) : [];
  List<String> get _thanas => _district != null
      ? (_districtThanas[_district] ?? ['${_district} Sadar', 'Other'])
      : [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? {};
    final providers = user.providerData.map((p) => p.providerId).toList();
    setState(() {
      _name = data['name'] as String? ?? user.displayName ?? '';
      _email = data['email'] as String? ?? user.email ?? '';
      _mobile = data['mobile'] as String? ?? '';
      _isGoogleUser = providers.contains('google.com') && _mobile.isEmpty;
      if (_isGoogleUser) _mobileCtrl.text = '';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isGoogleUser && _mobileCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'gender': _gender,
            'profession': _profession,
            'bloodGroup': _bloodGroup,
            'dob': _dob?.toIso8601String(),
            'division': _division,
            'district': _district,
            'thana': _thana,
            'profileComplete': true,
            if (_isGoogleUser && _mobileCtrl.text.trim().isNotEmpty)
              'mobile': _mobileCtrl.text.trim(),
          });
      if (mounted) context.go(AppRouter.createJoinMess);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Complete Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGreen, AppColors.buttonGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Just a few more details',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Personal Info
              _sectionTitle('👤 Personal Info'),
              const SizedBox(height: 12),
              _lockedField('Name', _name, Icons.person),
              const SizedBox(height: 12),
              _lockedField('Email', _email, Icons.email),
              const SizedBox(height: 12),
              if (_isGoogleUser) ...[
                _inputField(
                  controller: _mobileCtrl,
                  label: 'Mobile Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length != 11) return 'Must be 11 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ] else
                _lockedField('Mobile', _mobile, Icons.phone),
              const SizedBox(height: 12),
              _dropdown(
                'Gender',
                _genders,
                _gender,
                Icons.wc,
                (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Profession',
                _professions,
                _profession,
                Icons.work,
                (v) => setState(() => _profession = v),
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Blood Group',
                _bloodGroups,
                _bloodGroup,
                Icons.bloodtype,
                (v) => setState(() => _bloodGroup = v),
              ),
              const SizedBox(height: 12),
              _dobPicker(),
              const SizedBox(height: 24),

              // Location
              _sectionTitle('📍 Your Home Location'),
              const SizedBox(height: 12),
              _dropdown(
                'Division',
                _divisionDistricts.keys.toList(),
                _division,
                Icons.map,
                (v) {
                  setState(() {
                    _division = v;
                    _district = null;
                    _thana = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              _dropdown(
                'District',
                _districts,
                _district,
                Icons.location_city,
                _division == null
                    ? null
                    : (v) => setState(() {
                        _district = v;
                        _thana = null;
                      }),
                hint: _division == null
                    ? 'Select division first'
                    : 'Select district',
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Thana / Upazila',
                _thanas,
                _thana,
                Icons.place,
                _district == null ? null : (v) => setState(() => _thana = v),
                hint: _district == null
                    ? 'Select district first'
                    : 'Select thana',
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRouter.createJoinMess),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: AppColors.textDark,
    ),
  );

  Widget _lockedField(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                value.isNotEmpty ? value : '—',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
      ],
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
    ),
  );

  Widget _dropdown(
    String label,
    List<String> items,
    String? value,
    IconData icon,
    void Function(String?)? onChanged, {
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: onChanged == null ? Colors.grey.shade100 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
      hint: hint != null
          ? Text(hint, style: const TextStyle(fontSize: 13))
          : null,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dobPicker() => InkWell(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _dob ?? DateTime(2000),
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) setState(() => _dob = picked);
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.cake, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  _dob != null
                      ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 14,
                    color: _dob != null
                        ? AppColors.textDark
                        : Colors.grey.shade400,
                    fontWeight: _dob != null
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
        ],
      ),
    ),
  );
}
