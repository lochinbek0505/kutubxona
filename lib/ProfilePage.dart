import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'LoginScreen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _name = "Ism Familiya";
  String _email = "user@example.com";
  String _language = 'uz';
  bool _isDarkTheme = false;

  final Map<String, String> _languageOptions = {
    'uz': 'O‘zbekcha',
    'ru': 'Русский',
  };

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'uz';
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
    });

    // Load current user email
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _email = user.email!;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    await prefs.setBool('isDarkTheme', _isDarkTheme);
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _savePreferences();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_language == 'uz'
              ? "Profil ma'lumotlari saqlandi"
              : "Данные профиля сохранены"),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();

      // Clear preferences if needed
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to login screen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_language == 'uz'
              ? "Chiqishda xatolik yuz berdi"
              : "Ошибка при выходе"),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final bgColor = _isDarkTheme ? const Color(0xFF1E293B) : Colors.white;
        final textColor = _isDarkTheme ? Colors.white : Colors.black87;

        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            _language == 'uz' ? "Chiqish" : "Выход",
            style: TextStyle(color: textColor),
          ),
          content: Text(
            _language == 'uz'
                ? "Haqiqatan ham hisobdan chiqmoqchimisiz?"
                : "Вы действительно хотите выйти?",
            style: TextStyle(color: textColor),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                _language == 'uz' ? "Bekor qilish" : "Отмена",
                style: TextStyle(color: textColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                _language == 'uz' ? "Chiqish" : "Выйти",
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkTheme ? const Color(0xFF0F172A) : Colors.white;
    final textColor = _isDarkTheme ? Colors.white : Colors.black87;
    final cardColor = _isDarkTheme ? Colors.white.withOpacity(0.07) : Colors.grey[200];
    final accentColor = const Color(0xFF22C55E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _language == 'uz' ? "Profil sozlamalari" : "Настройки профиля",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: _language == 'uz' ? "Chiqish" : "Выйти",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInputField(
                    label: _language == 'uz' ? "Ism Familiya" : "Имя и Фамилия",
                    initialValue: _name,
                    validator: (val) =>
                    val == null || val.isEmpty ? (_language == 'uz' ? "Ismni kiriting" : "Введите имя") : null,
                    onSaved: (val) => _name = val ?? _name,
                    textColor: textColor,
                    cardColor: cardColor,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: "Email",
                    initialValue: _email,
                    enabled: false,
                    validator: (_) => null,
                    onSaved: (_) {},
                    textColor: textColor,
                    cardColor: cardColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              _language == 'uz' ? "Tilni tanlash" : "Выбор языка",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _language,
                dropdownColor: bgColor,
                iconEnabledColor: accentColor,
                style: GoogleFonts.poppins(color: textColor),
                items: _languageOptions.entries
                    .map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _language = val);
                    _savePreferences();
                  }
                },
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _language == 'uz' ? "Mavzu rejimi" : "Тема",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Switch(
                  activeColor: accentColor,
                  value: _isDarkTheme,
                  onChanged: (val) {
                    setState(() => _isDarkTheme = val);
                    _savePreferences();
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _language == 'uz' ? "Saqlash" : "Сохранить",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _showLogoutDialog,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _language == 'uz' ? "Chiqish" : "Выйти",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Column(
                children: [
                  Text(
                    "Sayfullayev Shahzod",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Toshkent axborot texnologiyalar universiteti samarqand filiali kompyuter injiniring fakulteti talabasi",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String initialValue,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
    required Color textColor,
    required Color? cardColor,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        initialValue: initialValue,
        validator: validator,
        onSaved: onSaved,
        keyboardType: keyboardType,
        enabled: enabled,
        style: GoogleFonts.poppins(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}