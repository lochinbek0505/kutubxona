import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'UploadBookPage.dart';
import 'ViewPage.dart';
import 'local_user_service.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({Key? key}) : super(key: key);

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> allBooks = [];
  String currentUserId = '';
  String searchQuery = '';
  var userData;

  String language = 'uz';
  bool isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadPreferences();
    loadUserId();
    fetchBooks();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('language') ?? 'uz';
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> loadUserId() async {
    userData = await LocalUserService.getUser();
    currentUserId = userData?['userId'] ?? '';
    setState(() {});
  }

  Future<void> fetchBooks() async {
    final snapshot = await FirebaseDatabase.instance.ref().child('books').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> data = snapshot.value as Map;
      List<Map<String, dynamic>> loadedBooks = [];

      data.forEach((key, value) {
        final book = Map<String, dynamic>.from(value);
        loadedBooks.add(book);
      });

      setState(() {
        allBooks = loadedBooks;
      });
    }
  }

  List<Map<String, dynamic>> filterBooks(String category) {
    return allBooks.where((book) {
      final matchesCategory = book['category'] == category;
      final matchesSearch =
          searchQuery.isEmpty ||
          (book['title']?.toLowerCase() ?? '').contains(
            searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final cardColor = isDarkTheme ? const Color(0xFF1E293B) : Colors.grey[200];
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    final subTextColor = isDarkTheme ? Colors.white70 : Colors.grey[700];

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 5,
      shadowColor: Colors.black87,
      child: InkWell(
        onTap: () {
          final allowedUsers = Map<String, dynamic>.from(
            book['allowedUsers'] ?? {},
          );
          if (book['status'] == 'public' ||
              allowedUsers.containsKey(currentUserId)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => PdfViewerPage(
                      title: book['title'],
                      pdfUrl: book['pdfUrl'],
                    ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  language == 'uz'
                      ? "Sizga bu kitob uchun ruxsat berilmagan"
                      : "У вас нет доступа к этой книге",
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Image.asset("assets/book.png", width: 80, height: 80),
              const SizedBox(height: 8),
              Column(
                children: [
                  Text(
                    book['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book['author'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: subTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 180,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return _buildBookCard(books[index]);
      },
    );
  }

  Widget _buildSearchField() {
    final bgColor = isDarkTheme ? const Color(0xFF1E293B) : Colors.grey[200];
    final hintColor = isDarkTheme ? Colors.white54 : Colors.grey[600];
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: TextStyle(color: textColor),
        cursorColor: Colors.tealAccent,
        decoration: InputDecoration(
          hintText:
              language == 'uz' ? 'Kitob nomini qidiring...' : 'Поиск книги...',
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkTheme ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          language == 'uz' ? '📖 Kitoblar' : '📖 Книги',
          style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildSearchField(),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.tealAccent,
                labelColor: isDarkTheme ? Colors.white : Colors.black,
                unselectedLabelColor:
                    isDarkTheme ? Colors.white54 : Colors.grey,
                tabs: [
                  Tab(
                    text: language == 'uz' ? '📚 Badiiy' : '📚 Художественные',
                  ),
                  Tab(text: language == 'uz' ? '📘 Darslik' : '📘 Учебники'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(filterBooks('Badiiy')),
          _buildGrid(filterBooks('Darslik')),
        ],
      ),
    );
  }
}
