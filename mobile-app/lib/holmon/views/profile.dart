import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:grocery_app/holmon/constants/appConstants.dart';
import 'package:grocery_app/holmon/constants/assets.dart';
import 'package:grocery_app/holmon/utils/helper.dart';
import 'package:grocery_app/holmon/utils/myTheme.dart';
import 'package:grocery_app/holmon/views/common_widgets/profileList.dart';
import 'package:grocery_app/features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'package:grocery_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:grocery_app/features/checkout/presentation/pages/order_history_screen.dart';
import 'package:lottie/lottie.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  static final Email email = Email(
    body: '',
    subject: 'subject',
    recipients: ['rami.omar.ayache@gmail.com'],
    isHTML: false,
  );

  String _userName = "FreshCart Customer";
  String _userEmail = "member@freshcart.com";
  String _userPhone = "";
  String _userLocation = "";
  String _userPassword = "";
  String _activeThemeKey = "organic_green";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: 'user_name');
    final emailVal = await storage.read(key: 'user_email');
    final phone = await storage.read(key: 'user_phone');
    final loc = await storage.read(key: 'user_location');
    final password = await storage.read(key: 'user_password') ?? '';

    final userThemeKey = 'theme_${emailVal ?? "guest"}';
    final savedThemeKey = await storage.read(key: userThemeKey) ?? 'organic_green';

    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        if (emailVal != null && emailVal.isNotEmpty) _userEmail = emailVal;
        if (phone != null) _userPhone = phone;
        if (loc != null) _userLocation = loc;
        _userPassword = password;
        _activeThemeKey = savedThemeKey;
      });
    }
  }

  Future<void> _applySelectedTheme(BuildContext context, String key) async {
    const storage = FlutterSecureStorage();
    final userThemeKey = 'theme_$_userEmail';
    await storage.write(key: userThemeKey, value: key);

    setState(() {
      _activeThemeKey = key;
    });

    final newTheme = AppThemes.getThemeByKey(key);
    ThemeSwitcher.of(context).changeTheme(
      theme: newTheme,
      isReversed: false,
    );
  }

  Widget _buildThemeCircle(BuildContext context, String key, Color color, String name) {
    final isSelected = _activeThemeKey == key;
    return GestureDetector(
      onTap: () => _applySelectedTheme(context, key),
      child: Tooltip(
        message: name,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? const Color(0xFF22C55E) : Colors.black12,
              width: isSelected ? 3.0 : 1.0,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              )
            ] : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return BlocListener<PhoneAuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Profile Picture Header
                Stack(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100)),
                          child: Image.asset(Assets.imagesUser)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: primaryColor),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_userName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(_userEmail, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),

                const Divider(thickness: 0.1),
                const SizedBox(height: 10),

                /// -- MENU
                ProfileMenuWidget(
                    title: "Edit Profile Preferences",
                    icon: Icons.account_circle,
                    onPress: () async {
                      final authRepo = RepositoryProvider.of<AuthRepository>(context);
                      await Get.to(() => EditProfileScreen(
                        authRepository: authRepo,
                        currentName: _userName,
                        currentPhone: _userPhone,
                        currentLocation: _userLocation,
                        currentPassword: _userPassword,
                      ));
                      _loadUserProfile(); // Reload profile details after returning
                    }),

                ProfileMenuWidget(
                    title: "Order History",
                    icon: Icons.receipt_long_outlined,
                    onPress: () {
                      Get.to(() => const OrderHistoryScreen());
                    }),

                // Persisted Premium Theme Selector Widget
                ThemeSwitcher(
                  builder: (context) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select App Theme",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildThemeCircle(context, 'organic_green', const Color(0xFF006E2F), "Organic"),
                              _buildThemeCircle(context, 'light_blue', const Color(0xff2382AA), "Blue"),
                              _buildThemeCircle(context, 'dark_blue', const Color(0xff1A3848), "Navy"),
                              _buildThemeCircle(context, 'sunset_orange', const Color(0xFFE65100), "Orange"),
                              _buildThemeCircle(context, 'royal_purple', const Color(0xFF6200EE), "Purple"),
                              _buildThemeCircle(context, 'premium_gold', const Color(0xFFD4AF37), "Gold"),
                              _buildThemeCircle(context, 'midnight_blue', const Color(0xFF0F172A), "Midnight"),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                ProfileMenuWidget(
                    title: "Delivery Preferences",
                    icon: Icons.delivery_dining,
                    onPress: () {}),
                ProfileMenuWidget(
                    title: "Change Location",
                    icon: Icons.settings,
                    onPress: () {}),
                const Divider(thickness: 0.1),
                const SizedBox(height: 10),
                ProfileMenuWidget(
                    title: "Terms & Conditions",
                    icon: Icons.info,
                    onPress: () {}),
                ProfileMenuWidget(
                    title: "About Us",
                    icon: Icons.developer_mode_rounded,
                    endIcon: true,
                    onPress: () {
                      Get.dialog(
                        Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            constraints: const BoxConstraints(maxHeight: 560),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    "Made With ❤️ By #${AppConstants.projectOwnerName}",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal),
                                  ),
                                  Lottie.asset(
                                    Assets.imagesCatThinking,
                                    addRepaintBoundary: true,
                                    width: 240,
                                    height: 180,
                                    repeat: false,
                                    decoder: customDecoder,
                                  ),
                                  const Text(
                                    "Rate our app",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 14),
                                  RatingBar.builder(
                                    initialRating: 5,
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onRatingUpdate: (rating) {
                                      print(rating);
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: ElevatedButton(
                                          onPressed: () async => {
                                            await Get.to(() => FlutterEmailSender.send(email))
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                          ),
                                          child: const Text(
                                            "Email us",
                                            style: TextStyle(
                                                fontSize: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                const Divider(thickness: 0.1),
                ProfileMenuWidget(
                    title: "Logout",
                    icon: Icons.logout,
                    endIcon: false,
                    onPress: () {
                      context.read<PhoneAuthBloc>().add(LogoutEvent());
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Premium Edit Profile Screen Widget
class EditProfileScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final String currentName;
  final String currentPhone;
  final String currentLocation;
  final String currentPassword;

  const EditProfileScreen({
    Key? key,
    required this.authRepository,
    required this.currentName,
    required this.currentPhone,
    required this.currentLocation,
    required this.currentPassword,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _passCtrl;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
    _phoneCtrl = TextEditingController(text: widget.currentPhone);
    _locCtrl = TextEditingController(text: widget.currentLocation);
    _passCtrl = TextEditingController(text: widget.currentPassword);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await widget.authRepository.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        location: _locCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profile updated successfully!"),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
        Get.back();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Edit Profile Preferences", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Full Name",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.person_outline_rounded, color: primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
              ),
              const SizedBox(height: 20),

              const Text(
                "Phone Number",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.phone_outlined, color: primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
              ),
              const SizedBox(height: 20),

              const Text(
                "Delivery City / Address",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locCtrl,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.location_on_outlined, color: primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter location' : null,
              ),
              const SizedBox(height: 20),

              const Text(
                "Password",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              StatefulBuilder(
                builder: (context, setPasswordState) {
                  return TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setPasswordState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter password';
                      if (v.length < 6) return 'Password must be 6+ characters';
                      return null;
                    },
                  );
                }
              ),
              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.35),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Save Settings',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
