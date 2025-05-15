import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  String _name = "Ism Familiya";
  String _email = "user@example.com";
  String _language = 'O‘zbekcha';
  bool _isDarkTheme = false;

  final List<String> _languages = ['O‘zbekcha', 'Русский', 'English'];

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil ma'lumotlari saqlandi")),
      );
      // Firebase yoki SharedPreferences saqlash kodini shu yerga qo'shing
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF0F172A); // background color (sahifa orqa fon)
    final cardColor = Colors.white.withOpacity(0.07);
    final accentColor = const Color(0xFF22C55E); // yashil ton (EditMyBooksPage bilan mos)

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Profil sozlamalari",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInputField(
                    label: "Ism Familiya",
                    initialValue: _name,
                    validator: (val) =>
                    val == null || val.isEmpty ? "Ismni kiriting" : null,
                    onSaved: (val) => _name = val ?? _name,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: "Email",
                    initialValue: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Emailni kiriting";
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) {
                        return "Noto‘g‘ri email";
                      }
                      return null;
                    },
                    onSaved: (val) => _email = val ?? _email,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              "Tilni tanlash",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
                style: GoogleFonts.poppins(color: Colors.white),
                items: _languages
                    .map((lang) => DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _language = val);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Mavzu rejimi",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Switch(
                  activeColor: accentColor,
                  value: _isDarkTheme,
                  onChanged: (val) {
                    setState(() => _isDarkTheme = val);
                    // Tema boshqaruvini kerak bo'lsa qo'shing
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
                  "Saqlash",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            Center(
              child: Column(
                children: [
                  Text(
                    "Ishlab chiqaruvchi",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Falcon Mobile\n\n"
                        "Manzil: Toshkent, O‘zbekiston\n"
                        "Email: support@falconmobile.uz\n"
                        "Telefon: +998 90 123 45 67",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    final cardColor = Colors.white.withOpacity(0.07);
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
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }
}
