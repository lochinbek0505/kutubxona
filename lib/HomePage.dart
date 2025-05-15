import 'package:flutter/material.dart';
import 'package:kutubxona/BooksPage.dart';
import 'package:kutubxona/MembersManagementPage.dart';
import 'package:kutubxona/ProfilePage.dart';
import 'package:kutubxona/edit_my_books_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    BooksPage(),
    MembersManagementPage(),
    EditMyBooksPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            // Home o‘rniga zamonaviy variant
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_rounded), // Users o‘rniga aniqroq ifoda
            label: "Users",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded), // Books uchun mos ikonka
            label: "Books",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            // Profile uchun yumaloq avatar
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
