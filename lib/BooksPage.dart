import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'local_user_service.dart'; // foydalanuvchi ID olish uchun

class BooksPage extends StatefulWidget {
  const BooksPage({Key? key}) : super(key: key);

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> allBooks = [];
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadUserId();
    fetchBooks();
  }

  Future<void> loadUserId() async {
    final userData = await LocalUserService.getUser();
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
        final allowedUsers = Map<String, dynamic>.from(book['allowedUsers'] ?? {});

        if (status == 'public' || allowedUsers.containsKey(currentUserId)) {
          loadedBooks.add(book);
        }
      });

      setState(() {
        allBooks = loadedBooks;
      });
    }
  }

  List<Map<String, dynamic>> filterByCategory(String category) {
    return allBooks.where((book) => book['category'] == category).toList();
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    return Card(
      elevation: 4,
      color: Colors.blueGrey.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: add reading or details screen
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.book, size: 48, color: Colors.tealAccent),
              const SizedBox(height: 8),
              Text(
                book['title'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                book['author'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Kitoblar', style: TextStyle(color: Colors.white)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.tealAccent,
            tabs: const [
              Tab(text: '📚 Badiiy'),
              Tab(text: '📘 Darslik'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGrid(filterByCategory('Badiiy')),
            _buildGrid(filterByCategory('Darslik')),
          ],
        ),
      ),
    );
  }
}
