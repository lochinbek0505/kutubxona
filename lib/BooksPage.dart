import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadUserId();
    fetchBooks();
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
        final status = book['status'];
        final allowedUsers = Map<String, dynamic>.from(
          book['allowedUsers'] ?? {},
        );

        // if (status == 'public' || allowedUsers.containsKey(currentUserId)) {
        loadedBooks.add(book);
        // }
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
    return Card(
      color: const Color(0xFF1E293B),
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
              SnackBar(content: Text("Sizga bu kitob uchun ruxsat berilmagan")),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      color: Colors.white,
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
                      color: Colors.white70,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.tealAccent,
        decoration: const InputDecoration(
          hintText: 'Kitob nomini qidiring...',
          hintStyle: TextStyle(color: Colors.white54),
          prefixIcon: Icon(Icons.search, color: Colors.tealAccent),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('📖 Kitoblar', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildSearchField(),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.tealAccent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [Tab(text: '📚 Badiiy'), Tab(text: '📘 Darslik')],
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
