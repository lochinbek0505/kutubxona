import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'EditBooks.dart';
import 'UploadBookPage.dart';
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

  String language = 'uz';
  bool isDarkTheme = false;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('language') ?? 'uz';
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  String t(String uz, String ru) {
    return language == 'ru' ? ru : uz;
  }

  Color get backgroundColor => isDarkTheme ? const Color(0xFF0F172A) : Colors.white;
  Color get cardColor => isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey.shade200;
  Color get textColor => isDarkTheme ? Colors.white : Colors.black87;
  Color get subTextColor => isDarkTheme ? Colors.white70 : Colors.black54;
  Color get iconColor => isDarkTheme ? Colors.white : Colors.black87;

  Future<void> getId() async {
    var data = await LocalUserService.getUser();
    userId = data!["userId"]!;
    setState(() {
      isLoading = true;
    });
  }

  @override
  void initState() {
    super.initState();
    loadPreferences();
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
      myBooks = tempBooks.reversed.toList(); // oxirgi qo‘shilgan birinchi chiqadi
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
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          t("Kitobni o'chirish", "Удалить книгу"),
          style: TextStyle(color: textColor),
        ),
        content: Text(
          t("Haqiqatan ham ushbu kitobni o'chirmoqchimisiz?", "Вы уверены, что хотите удалить эту книгу?"),
          style: TextStyle(color: subTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t("Bekor qilish", "Отмена"),
              style: TextStyle(color: subTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await deleteBook(bookId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(t("O'chirish", "Удалить")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDarkTheme ? const Color(0xFF1E293B) : Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadBookPage()),
          );
        },
      ),
      appBar: AppBar(
        title: Text(
          t("Mening kitoblarim", "Мои книги"),
          style: TextStyle(color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
      ),
      body: !isLoading
          ? Center(child: CircularProgressIndicator(color: iconColor))
          : myBooks.isEmpty
          ? Center(
        child: Text(
          t("Siz hech qanday kitob qo‘shmagansiz", "Вы не добавили ни одной книги"),
          style: TextStyle(color: subTextColor),
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
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subTextColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "📖 ${t("Muallif", "Автор")}: ${book['author']}",
                  style: TextStyle(color: subTextColor),
                ),
                Text(
                  "📄 ${t("Tavsif", "Описание")}: ${book['description']}",
                  style: TextStyle(color: subTextColor),
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
                      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                      label: Text(
                        t("Tahrirlash", "Редактировать"),
                        style: const TextStyle(color: Colors.white),
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
                      icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                      label: Text(
                        t("O'chirish", "Удалить"),
                        style: const TextStyle(color: Colors.white),
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
