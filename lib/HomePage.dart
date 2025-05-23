import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _language = 'uz';
  bool _isDarkTheme = false;
  String _userEmail = '';
  bool _isAdmin = false;

  List<Widget> _pages = [];

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    setState(() {
      _language = prefs.getString('language') ??   'uz';
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
      _userEmail = email;
      _isAdmin = email == 'admin@gmail.com';

      // Build pages based on role
      _pages = [
        BooksPage(),
        if (_isAdmin) MembersManagementPage(),
        EditMyBooksPage(),
        ProfilePage(),
      ];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkTheme ? const Color(0xFF0F172A) : Colors.white;
    final navBarColor =
        _isDarkTheme ? const Color(0xFF1E293B) : Colors.grey[100];
    final selectedColor = _isDarkTheme ? Colors.white : Colors.black;
    final unselectedColor = _isDarkTheme ? Colors.grey.shade400 : Colors.grey;

    final bottomNavItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard_rounded),
        label: _language == 'uz' ? "Kitoblar" : "Books",
      ),
      if (_isAdmin)
        BottomNavigationBarItem(
          icon: const Icon(Icons.group_rounded),
          label: _language == 'uz' ? "A'zolar" : "Members",
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.menu_book_rounded),
        label: _language == 'uz' ? "Mening kitoblarim" : "My Books",
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.account_circle_rounded),
        label: _language == 'uz' ? "Profil" : "Profile",
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: navBarColor,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: bottomNavItems,
      ),
    );
  }
}
