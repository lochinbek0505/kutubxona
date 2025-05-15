import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'EditBooks.dart';
import 'local_user_service.dart';

class EditMyBooksPage extends StatefulWidget {
  const EditMyBooksPage({super.key});

  @override
  State<EditMyBooksPage> createState() => _EditMyBooksPageState();
}

class _EditMyBooksPageState extends State<EditMyBooksPage> {
  List<Map<String, dynamic>> myBooks = [];
  bool isLoading = false;
  var userId = '';

  getId() async {
    var data = await LocalUserService.getUser();
    userId = data!["userId"]!;
    setState(() {
      isLoading = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getId();
    fetchMyBooks();
  }

  Future<void> fetchMyBooks() async {
    setState(() {
      isLoading = false;
    });
    final snapshot = await FirebaseDatabase.instance.ref().child('books').get();
    final List<Map<String, dynamic>> tempBooks = [];

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;
      data.forEach((key, value) {
        final book = Map<String, dynamic>.from(value);
        if (book['authorId'] == userId) {
          tempBooks.add(book);
        }
      });
    }

    setState(() {
      myBooks =
          tempBooks.reversed.toList(); // oxirgi qo‘shilgan birinchi chiqadi
      isLoading = true;
    });
  }

  Future<void> deleteBook(String bookId) async {
    await FirebaseDatabase.instance.ref().child('books').child(bookId).remove();
    fetchMyBooks();
  }

  void showDeleteDialog(String bookId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              "Kitobni o'chirish",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Haqiqatan ham ushbu kitobni o'chirmoqchimisiz?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Bekor qilish",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await deleteBook(bookId);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text("O'chirish"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Mening kitoblarim",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          !isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : myBooks.isEmpty
              ? const Center(
                child: Text(
                  "Siz hech qanday kitob qo‘shmagansiz",
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: myBooks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final book = myBooks[index];
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
                        Text(
                          book['title'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "📖 Muallif: ${book['author']}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "📄 Tavsif: ${book['description']}",
                          style: const TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (b) => EditBookPage(data: book),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Tahrirlash",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDeleteDialog(book['bookId']);
                              },
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "O'chirish",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
