import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kutubxona/HomePage.dart';

import 'local_user_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  String language = 'uz';
  bool isDarkTheme = false;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('language') ?? 'uz';
      isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
    });
  }

  String t(String uz, String ru) => language == 'ru' ? ru : uz;

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage(t("Iltimos, barcha maydonlarni to'ldiring", "Пожалуйста, заполните все поля"));
      return;
    }

    try {
      setState(() => isLoading = true);
      final auth = FirebaseAuth.instance;

      final userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;

      final userSnapshot =
      await FirebaseDatabase.instance.ref().child('users').child(userId).get();

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        await LocalUserService.saveUser(
          userId: userId,
          name: userData['name'] ?? 'Noma’lum',
          email: userData['email'] ?? '',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        _showMessage(t("Foydalanuvchi topilmadi", "Пользователь не найден"));
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? t("Tizimga kirishda xatolik yuz berdi", "Ошибка входа"));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkTheme ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final hintTextColor = isDarkTheme ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Kutubxona',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 40),
                _glassTextField(emailController, t("Email", "Электронная почта"), Icons.email, textColor, hintTextColor),
                const SizedBox(height: 20),
                _glassTextField(
                  passwordController,
                  t("Parol", "Пароль"),
                  Icons.lock,
                  textColor,
                  hintTextColor,
                  obscure: true,
                ),
                const SizedBox(height: 30),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    t("Kirish", "Войти"),
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: Text(
                    t("Ro’yxatdan o’tish", "Зарегистрироваться"),
                    style: TextStyle(color: hintTextColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassTextField(
      TextEditingController controller,
      String hint,
      IconData icon,
      Color textColor,
      Color hintTextColor, {
        bool obscure = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintText: hint,
          hintStyle: TextStyle(color: hintTextColor),
          prefixIcon: Icon(icon, color: hintTextColor),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
