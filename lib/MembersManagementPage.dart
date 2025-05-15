// Siz yuborgan kodingiz o'zgartirildi va to'ldirildi:
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';

class MembersManagementPage extends StatefulWidget {
  const MembersManagementPage({super.key});

  @override
  State<MembersManagementPage> createState() => _MembersManagementPageState();
}

class _MembersManagementPageState extends State<MembersManagementPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> users = [];
  Map<String, List<Map<String, dynamic>>> rentedBooksMap = {};
  bool isLoading = true;
  late TabController _tabController;
  String userSearch = '';
  String bookSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchUsersAndRentals();
  }

  Future<void> fetchUsersAndRentals() async {
    try {
      final usersSnap =
          await FirebaseDatabase.instance
              .ref()
              .child('users')
              .orderByChild('createdAt')
              .get();
      if (usersSnap.exists) {
        final Map data = usersSnap.value as Map;
        users =
            data.entries
                .map((entry) {
                  final user = Map<String, dynamic>.from(entry.value);
                  return user;
                })
                .toList()
                .reversed
                .toList();
      }

      final rentedSnap =
          await FirebaseDatabase.instance.ref().child('rentedBooks').get();
      if (rentedSnap.exists) {
        final Map rentalsData = rentedSnap.value as Map;
        rentedBooksMap = rentalsData.map((userId, booksMap) {
          final books =
              (booksMap as Map).entries.map((e) {
                final book = Map<String, dynamic>.from(e.value);
                book['rentalId'] = e.key;
                return book;
              }).toList();
          return MapEntry(userId, books);
        });
      }
    } catch (e) {
      debugPrint("Xatolik: ${e.toString()}");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "A’zolarni boshqarish",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "A’zolar"), Tab(text: "Ijaradagi kitoblar")],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.tealAccent,
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      _searchBar(
                        (v) => setState(() => userSearch = v),
                        "Foydalanuvchi izlash...",
                      ),
                      Expanded(child: _buildUsersTab()),
                    ],
                  ),
                  Column(
                    children: [
                      _searchBar(
                        (v) => setState(() => bookSearch = v),
                        "Kitob yoki foydalanuvchi izlash...",
                      ),
                      Expanded(child: _buildRentedBooksTab()),
                    ],
                  ),
                ],
              ),
    );
  }

  Widget _searchBar(Function(String) onChanged, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    final filteredUsers =
        users.where((user) {
          final name = (user['name'] ?? '').toString().toLowerCase();
          return name.contains(userSearch.toLowerCase());
        }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          "A’zolar topilmadi",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(filteredUsers[index]);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
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
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          _infoRow("📧", email),
          _infoRow("🆔", "ID: $userId"),
          _infoRow("📚", "Yuklab olingan: $downloads ta"),
          _infoRow("📖", "Ijarada: $borrowed ta"),
          _infoRow("📅", "Qo‘shilgan: $createdDate", subtle: true),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showRentalDialog(userId, name),
              icon: const Icon(Icons.library_add),
              label: const Text("Ijaraga berish"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentedBooksTab() {
    final filteredEntries =
        rentedBooksMap.entries.where((entry) {
          final user = users.firstWhere(
            (u) => u['userId'] == entry.key,
            orElse: () => {},
          );
          final name = (user['name'] ?? '').toString().toLowerCase();

          final matchUser = name.contains(bookSearch.toLowerCase());

          final matchBook = entry.value.any(
            (book) => book['bookName'].toString().toLowerCase().contains(
              bookSearch.toLowerCase(),
            ),
          );

          return matchUser || matchBook;
        }).toList();

    if (filteredEntries.isEmpty) {
      return Center(
        child: Text(
          "Ijaradagi kitoblar topilmadi",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          filteredEntries.map((entry) {
            final userId = entry.key;
            final books = entry.value;
            final user = users.firstWhere(
              (u) => u['userId'] == userId,
              orElse: () => {'name': 'Noma’lum foydalanuvchi'},
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  ...books.map((book) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "👤 ${book['userName']}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          _infoRow("📚", "Kitob: ${book['bookName']}"),
                          _infoRow("📅", "Sana: ${book['rentalDate']}"),
                          _infoRow("⏳", "Muddati: ${book['rentalDays']} kun"),
                          if (book['barcode'] != null &&
                              book['barcode'].toString().isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow("🔖", "Barcode: ${book['barcode']}"),
                                BarcodeWidget(
                                  barcode: Barcode.code128(),
                                  data: book['barcode'],
                                  width: 200,
                                  height: 60,
                                  backgroundColor: Colors.white,
                                ),
                              ],
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                books.remove(book);
                                await FirebaseDatabase.instance
                                    .ref()
                                    .child('rentedBooks')
                                    .child(userId)
                                    .child(book['rentalId'])
                                    .remove();

                                // Agar foydalanuvchida boshqa ijaradagi kitob qolmagan bo‘lsa, xaritadan o‘chirib tashlang
                                if (books.isEmpty) {
                                  rentedBooksMap.remove(userId);
                                }

                                setState(() {}); // UI yangilash
                                await fetchUsersAndRentals(); // Firebase'dan yangilangan ma'lumotni olish
                              },

                              icon: const Icon(
                                Icons.check,
                                color: Colors.greenAccent,
                              ),
                              label: const Text(
                                "Qaytarildi",
                                style: TextStyle(color: Colors.greenAccent),
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white24),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _infoRow(String emoji, String text, {bool subtle = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$emoji $text",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: subtle ? Colors.white38 : Colors.white70,
        ),
      ),
    );
  }

  void _showRentalDialog(String userId, String userName) {
    final bookController = TextEditingController();
    final daysController = TextEditingController();
    final barcodeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "📖 $userName foydalanuvchiga ijaraga berish",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInput(bookController, "Kitob nomi"),
                const SizedBox(height: 10),
                _buildInput(daysController, "Ijara muddati (kun)"),
                const SizedBox(height: 10),
                _buildInput(barcodeController, "Kitob barcode (ixtiyoriy)"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Bekor",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = bookController.text.trim();
                  final days = int.tryParse(daysController.text.trim()) ?? 0;
                  final barcode = barcodeController.text.trim();

                  if (name.isEmpty || days <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Iltimos, barcha maydonlarni to'g'ri to'ldiring",
                        ),
                      ),
                    );
                    return;
                  }

                  final rentalId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  final rentalRef = FirebaseDatabase.instance
                      .ref()
                      .child('rentedBooks')
                      .child(userId)
                      .child(rentalId);

                  await rentalRef.set({
                    'bookName': name,
                    'barcode': barcode,
                    'rentalDays': days,
                    'userName': userName,
                    'rentalDate': DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.now()),
                  });

                  Navigator.pop(context);
                  fetchUsersAndRentals();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Kitob muvaffaqiyatli ijaraga berildi"),
                    ),
                  );
                },
                child: const Text("Berish"),
              ),
            ],
          ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType:
          hint.contains("muddat") ? TextInputType.number : TextInputType.text,
    );
  }
}
