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
    final snapshot = await FirebaseDatabase.instance.ref().child('books').get();
    final List<Map<String, dynamic>> tempBooks = [];

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;
      data.forEach((key, value) {
        final book = Map<String, dynamic>.from(value);
        if (
            book['authorId'] == userId) {
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

  void showEditDialog(Map<String, dynamic> book) {
    final titleController = TextEditingController(text: book['title']);
    final authorController = TextEditingController(text: book['author']);
    final descController = TextEditingController(text: book['description']);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              "Kitobni tahrirlash",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Sarlavha",
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                TextField(
                  controller: authorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Muallif",
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Tavsif",
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
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
                  final updatedBook = {
                    'title': titleController.text.trim(),
                    'author': authorController.text.trim(),
                    'description': descController.text.trim(),
                  };

                  await FirebaseDatabase.instance
                      .ref()
                      .child('books')
                      .child(book['bookId'])
                      .update(updatedBook);

                  Navigator.pop(context);
                  fetchMyBooks(); // yangilash
                },
                child: const Text("Saqlash"),
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (b)=> EditBookPage(data: book)));

                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("Tahrirlash"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
