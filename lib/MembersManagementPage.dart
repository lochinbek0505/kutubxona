import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MembersManagementPage extends StatefulWidget {
  const MembersManagementPage({super.key});

  @override
  State<MembersManagementPage> createState() => _MembersManagementPageState();
}

class _MembersManagementPageState extends State<MembersManagementPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final snapshot = await FirebaseDatabase.instance.ref().child('users').orderByChild('createdAt').get();

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;

      users = data.entries.map((entry) {
        final user = Map<String, dynamic>.from(entry.value);
        return user;
      }).toList().reversed.toList(); // createdAt bo‘yicha teskari tartib
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          "A’zolarni boshqarish",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : users.isEmpty
          ? const Center(
        child: Text("A’zolar topilmadi", style: TextStyle(color: Colors.white)),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final user = users[index];
          final name = user['name'] ?? '';
          final email = user['email'] ?? '';
          final userId = user['userId'] ?? '';
          final downloads = user['downloadedBooks'] ?? 0;
          final borrowed = user['borrowedBooks'] ?? 0;

          String createdDate = 'Noma’lum';
          try {
            final createdAtStr = user['createdAt'];
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null) {
              createdDate = DateFormat('yyyy-MM-dd').format(createdAt);
            }
          } catch (e) {
            createdDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 6),
                Text("📧 $email", style: const TextStyle(color: Colors.white70)),
                Text("🆔 ID: $userId", style: const TextStyle(color: Colors.white70)),
                Text("📚 Yuklab olingan: $downloads ta", style: const TextStyle(color: Colors.white70)),
                Text("📖 Ijarada: $borrowed ta", style: const TextStyle(color: Colors.white70)),
                Text("📅 Qo‘shilgan: $createdDate", style: const TextStyle(color: Colors.white38)),
              ],
            ),
          );
        },
      ),
    );
  }
}
