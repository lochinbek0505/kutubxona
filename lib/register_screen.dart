import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LoginScreen.dart';
import 'local_user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  String _language = 'uz';
  bool _isDarkTheme = false;

  // Localization texts
  final Map<String, Map<String, String>> translations = {
    'register_title': {
      'uz': "Ro'yxatdan o'tish",
      'ru': "Регистрация",
    },
    'name_hint': {
      'uz': "Ismingiz",
      'ru': "Ваше имя",
    },
    'email_hint': {
      'uz': "Email",
      'ru': "Электронная почта",
    },
    'password_hint': {
      'uz': "Parol",
      'ru': "Пароль",
    },
    'register_button': {
      'uz': "Ro'yxatdan o'tish",
      'ru': "Зарегистрироваться",
    },
    'login_prompt': {
      'uz': "Hisobga kirish",
      'ru': "Войти в аккаунт",
    },
    'validation_error': {
      'uz': "Iltimos, barcha maydonlarni to'g'ri to'ldiring.",
      'ru': "Пожалуйста, правильно заполните все поля.",
    },
    'register_success': {
      'uz': "Ro'yxatdan o'tildi!",
      'ru': "Регистрация успешна!",
    },
    'register_error': {
      'uz': "Ro'yxatdan o'tishda xatolik yuz berdi.",
      'ru': "Ошибка при регистрации.",
    },
  };

  String t(String key) => translations[key]?[_language] ?? key;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'uz';
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    await prefs.setBool('isDarkTheme', _isDarkTheme);
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      _showMessage(t('validation_error'));
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;
      final userId = generateUserId(uid);

      await FirebaseDatabase.instance.ref().child('users').child(uid).set({
        'name': name,
        'email': email,
        'userId': userId,
        'downloadedBooks': 0,
        'borrowedBooks': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await LocalUserService.saveUser(userId: userId, name: name, email: email);

      _showMessage(t('register_success'));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? t('register_error'));
    } catch (e) {
      _showMessage("Xatolik: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String generateUserId(String uid) {
    final shortId = uid.substring(0, 6).toUpperCase();
    return 'USER_$shortId';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkTheme ? const Color(0xFF0F172A) : Colors.white;
    final textColor = _isDarkTheme ? Colors.white : Colors.black87;
    final cardColor = _isDarkTheme ? Colors.white.withOpacity(0.07) : Colors.grey[200];
    final accentColor = const Color(0xFF22C55E);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  t('register_title'),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 30),
                _buildInputField(
                  controller: nameController,
                  hint: t('name_hint'),
                  icon: Icons.person,
                  textColor: textColor,
                  cardColor: cardColor,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: emailController,
                  hint: t('email_hint'),
                  icon: Icons.email,
                  textColor: textColor,
                  cardColor: cardColor,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: passwordController,
                  hint: t('password_hint'),
                  icon: Icons.lock,
                  obscure: true,
                  textColor: textColor,
                  cardColor: cardColor,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      t('register_button'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    t('login_prompt'),
                    style: GoogleFonts.poppins(
                      color: accentColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color textColor,
    required Color? cardColor,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(color: textColor),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: textColor.withOpacity(0.6)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}