import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage("Iltimos, barcha maydonlarni to'ldiring");
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

      // Realtime databasedan user ma'lumotlarini olish
      final userSnapshot =
          await FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(userId)
              .get();

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        await LocalUserService.saveUser(
          userId: userId,
          name: userData['name'] ?? 'Noma’lum',
          email: userData['email'] ?? '',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MergeableMaterial()),
        );
      } else {
        _showMessage("Foydalanuvchi topilmadi");
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Tizimga kirishda xatolik yuz berdi');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                _glassTextField(emailController, 'Email', Icons.email),
                const SizedBox(height: 20),
                _glassTextField(
                  passwordController,
                  'Parol',
                  Icons.lock,
                  obscure: true,
                ),
                const SizedBox(height: 30),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 80,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Kirish",
                        style: GoogleFonts.poppins(fontSize: 18,color: Colors.white),
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
                  child: const Text(
                    "Ro’yxatdan o’tish",
                    style: TextStyle(color: Colors.white70),
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
    IconData icon, {
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
