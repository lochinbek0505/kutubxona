import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      _showMessage("Iltimos, barcha maydonlarni to'g'ri to'ldiring.");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Auth orqali foydalanuvchini ro’yxatdan o’tkazish
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;
      final userId = generateUserId(uid);

      // Realtime Database-ga yozish
      await FirebaseDatabase.instance.ref().child('users').child(uid).set({
        'name': name,
        'email': email,
        'userId': userId,
        'downloadedBooks': 0,
        'borrowedBooks': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Localga saqlash
      await LocalUserService.saveUser(userId: userId, name: name, email: email);

      _showMessage('Ro‘yxatdan o‘tildi!');

      // HomeScreen-ga o‘tish
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Ro’yxatdan o’tishda xatolik yuz berdi.");
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Ro’yxatdan o’tish',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                _glassTextField(nameController, 'Ismingiz', Icons.person),
                const SizedBox(height: 20),
                _glassTextField(emailController, 'Email', Icons.email),
                const SizedBox(height: 20),
                _glassTextField(
                  passwordController,
                  'Parol',
                  Icons.lock,
                  obscure: true,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 70,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            "Ro’yxatdan o’tish",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text("Hisobga kirish"),
                ),
                // TextButton
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
