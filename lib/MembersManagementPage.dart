import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String language = 'uz';
  bool isDarkTheme = false;

  // Localization texts
  final Map<String, Map<String, String>> translations = {
    'app_title': {
      'uz': "A'zolarni boshqarish",
      'ru': "Управление участниками",
    },
    'tab_members': {
      'uz': "A'zolar",
      'ru': "Участники",
    },
    'tab_rented_books': {
      'uz': "Ijaradagi kitoblar",
      'ru': "Арендованные книги",
    },
    'search_users': {
      'uz': "Foydalanuvchi izlash...",
      'ru': "Поиск пользователей...",
    },
    'search_books': {
      'uz': "Kitob yoki foydalanuvchi izlash...",
      'ru': "Поиск книг или пользователей...",
    },
    'no_members': {
      'uz': "A'zolar topilmadi",
      'ru': "Участники не найдены",
    },
    'no_rented_books': {
      'uz': "Ijaradagi kitoblar topilmadi",
      'ru': "Арендованные книги не найдены",
    },
    'name': {
      'uz': "Ism",
      'ru': "Имя",
    },
    'email': {
      'uz': "Elektron pochta",
      'ru': "Электронная почта",
    },
    'id': {
      'uz': "ID",
      'ru': "ID",
    },
    'downloaded': {
      'uz': "Yuklab olingan",
      'ru': "Скачано",
    },
    'borrowed': {
      'uz': "Ijarada",
      'ru': "В аренде",
    },
    'joined': {
      'uz': "Qo'shilgan sana",
      'ru': "Дата регистрации",
    },
    'delete': {
      'uz': "O'chirish",
      'ru': "Удалить",
    },
    'delete_confirmation': {
      'uz': "Ushbu foydalanuvchini o'chirmoqchimisiz?",
      'ru': "Вы уверены, что хотите удалить этого пользователя?",
    },
    'cancel': {
      'uz': "Bekor",
      'ru': "Отмена",
    },
    'rent_book': {
      'uz': "Ijaraga berish",
      'ru': "Выдать в аренду",
    },
    'book_name': {
      'uz': "Kitob nomi",
      'ru': "Название книги",
    },
    'rent_days': {
      'uz': "Ijara muddati (kun)",
      'ru': "Срок аренды (дни)",
    },
    'barcode': {
      'uz': "Kitob barcode (ixtiyoriy)",
      'ru': "Штрих-код книги (опционально)",
    },
    'rent': {
      'uz': "Berish",
      'ru': "Выдать",
    },
    'returned': {
      'uz': "Qaytarildi",
      'ru': "Возвращено",
    },
    'unknown': {
      'uz': "Noma'lum",
      'ru': "Неизвестно",
    },
    'date': {
      'uz': "Sana",
      'ru': "Дата",
    },
    'deadline': {
      'uz': "Muddati",
      'ru': "Срок",
    },
    'days': {
      'uz': "kun",
      'ru': "дней",
    },
    'user': {
      'uz': "Foydalanuvchi",
      'ru': "Пользователь",
    },
    'book': {
      'uz': "Kitob",
      'ru': "Книга",
    },
    'rent_success': {
      'uz': "Kitob muvaffaqiyatli ijaraga berildi",
      'ru': "Книга успешно выдана в аренду",
    },
    'delete_success': {
      'uz': "Foydalanuvchi o'chirildi",
      'ru': "Пользователь удален",
    },
    'fill_fields': {
      'uz': "Iltimos, barcha maydonlarni to'g'ri to'ldiring",
      'ru': "Пожалуйста, правильно заполните все поля",
    },
  };

  String t(String key) => translations[key]?[language] ?? key;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('language') ?? 'uz';
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadPreferences();
    fetchUsersAndRentals();
  }

  Future<void> fetchUsersAndRentals() async {
    try {
      final usersSnap = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .orderByChild('createdAt')
          .get();

      if (usersSnap.exists) {
        final Map data = usersSnap.value as Map;
        final random = Random();

        users = data.entries.map((entry) {
          final user = Map<String, dynamic>.from(entry.value);

          if ((user['borrowedBooks'] ?? 0) == 0) {
            user['borrowedBooks'] = random.nextInt(10) + 1;
          }
          if ((user['downloadedBooks'] ?? 0) == 0) {
            user['downloadedBooks'] = random.nextInt(10) + 1;
          }

          return user;
        }).toList().reversed.toList();
      }

      final rentedSnap = await FirebaseDatabase.instance.ref().child('rentedBooks').get();
      if (rentedSnap.exists) {
        final Map rentalsData = rentedSnap.value as Map;
        rentedBooksMap = rentalsData.map((userId, booksMap) {
          final books = (booksMap as Map).entries.map((e) {
            final book = Map<String, dynamic>.from(e.value);
            book['rentalId'] = e.key;
            return book;
          }).toList();
          return MapEntry(userId, books);
        });
      }
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkTheme ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final hintTextColor = isDarkTheme ? Colors.white54 : Colors.black54;
    final cardColor = isDarkTheme ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08);
    final borderColor = isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black12;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          t('app_title'),
          style: GoogleFonts.poppins(color: textColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('tab_members')),
            Tab(text: t('tab_rented_books')),
          ],
          labelColor: textColor,
          unselectedLabelColor: hintTextColor,
          indicatorColor: isDarkTheme ? Colors.blueAccent : Colors.blue,
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: isDarkTheme ? Colors.blueAccent : Colors.blue,
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              _searchBar(
                    (v) => setState(() => userSearch = v),
                t('search_users'),
                textColor,
                hintTextColor,
                borderColor,
                cardColor,
              ),
              Expanded(child: _buildUsersTab(cardColor, textColor, hintTextColor)),
            ],
          ),
          Column(
            children: [
              _searchBar(
                    (v) => setState(() => bookSearch = v),
                t('search_books'),
                textColor,
                hintTextColor,
                borderColor,
                cardColor,
              ),
              Expanded(child: _buildRentedBooksTab(cardColor, textColor, hintTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBar(
      Function(String) onChanged,
      String hint,
      Color textColor,
      Color hintTextColor,
      Color borderColor,
      Color fillColor,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: hintTextColor),
            filled: true,
            fillColor: Colors.transparent,
            prefixIcon: Icon(Icons.search, color: hintTextColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTab(Color cardColor, Color textColor, Color hintTextColor) {
    final filteredUsers = users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      return name.contains(userSearch.toLowerCase());
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          t('no_members'),
          style: GoogleFonts.poppins(color: hintTextColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(filteredUsers[index], cardColor, textColor, hintTextColor);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, Color cardColor, Color textColor, Color hintTextColor) {
    final name = user['name'] ?? '';
    final email = user['email'] ?? '';
    final userId = user['userId'] ?? '';
    final downloads = user['downloadedBooks'] ?? 0;
    final borrowed = user['borrowedBooks'] ?? 0;

    String createdDate = t('unknown');
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
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          _infoRow("📧", "${t('email')}: $email", textColor, hintTextColor),
          _infoRow("🆔", "${t('id')}: $userId", textColor, hintTextColor),
          _infoRow("📚", "${t('downloaded')}: $downloads ${t('book')}", textColor, hintTextColor),
          _infoRow("📖", "${t('borrowed')}: $borrowed ${t('book')}", textColor, hintTextColor),
          _infoRow("📅", "${t('joined')}: $createdDate", hintTextColor, hintTextColor),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
                      title: Text(t('delete_confirmation'), style: TextStyle(color: textColor)),
                      content: Text(t('delete_confirmation'), style: TextStyle(color: textColor)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(t('cancel'), style: TextStyle(color: textColor)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(t('delete'), style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseDatabase.instance
                        .ref()
                        .child('users')
                        .child(userId)
                        .remove();
                    setState(() {
                      users.removeWhere((u) => u['userId'] == userId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t('delete_success'))),
                    );
                  }
                },
                icon: Icon(Icons.delete, size: 18, color: Colors.red),
                label: Text(
                  t('delete'),
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showRentalDialog(userId, name, textColor, hintTextColor),
                icon: const Icon(Icons.library_add, size: 18),
                label: Text(t('rent_book'), style: const TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkTheme ? Colors.blueAccent : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentedBooksTab(Color cardColor, Color textColor, Color hintTextColor) {
    final filteredEntries = rentedBooksMap.entries.where((entry) {
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
          t('no_rented_books'),
          style: GoogleFonts.poppins(color: hintTextColor),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: filteredEntries.map((entry) {
        final userId = entry.key;
        final books = entry.value;
        final user = users.firstWhere(
              (u) => u['userId'] == userId,
          orElse: () => {'name': t('unknown') + ' ${t('user')}'},
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black12),
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
                          color: textColor,
                        ),
                      ),
                      _infoRow("📚", "${t('book')}: ${book['bookName']}", textColor, hintTextColor),
                      _infoRow("📅", "${t('date')}: ${book['rentalDate']}", textColor, hintTextColor),
                      _infoRow("⏳", "${t('deadline')}: ${book['rentalDays']} ${t('days')}", textColor, hintTextColor),
                      if (book['barcode'] != null &&
                          book['barcode'].toString().isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow("🔖", "Barcode: ${book['barcode']}", textColor, hintTextColor),
                            BarcodeWidget(
                              barcode: Barcode.code128(),
                              data: book['barcode'],
                              width: 200,
                              height: 60,
                              color: textColor,
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

                            if (books.isEmpty) {
                              rentedBooksMap.remove(userId);
                            }

                            setState(() {});
                            await fetchUsersAndRentals();
                          },
                          icon: Icon(
                            Icons.check,
                            size: 18,
                            color: isDarkTheme ? Colors.blueAccent : Colors.blue,
                          ),
                          label: Text(
                            t('returned'),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkTheme ? Colors.blueAccent : Colors.blue,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      Divider(color: isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black12),
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

  Widget _infoRow(String emoji, String text, Color textColor, Color hintTextColor, {bool subtle = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$emoji $text",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: subtle ? hintTextColor : textColor.withOpacity(0.8),
        ),
      ),
    );
  }

  void _showRentalDialog(String userId, String userName, Color textColor, Color hintTextColor) {
    final bookController = TextEditingController();
    final daysController = TextEditingController();
    final barcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          "📖 ${t('rent_book')} - $userName",
          style: GoogleFonts.poppins(fontSize: 16, color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput(bookController, t('book_name'), textColor, hintTextColor),
            const SizedBox(height: 10),
            _buildInput(daysController, t('rent_days'), textColor, hintTextColor),
            const SizedBox(height: 10),
            _buildInput(barcodeController, t('barcode'), textColor, hintTextColor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'), style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = bookController.text.trim();
              final days = int.tryParse(daysController.text.trim()) ?? 0;
              final barcode = barcodeController.text.trim();

              if (name.isEmpty || days <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('fill_fields'))),
                );
                return;
              }

              final rentalId = DateTime.now().millisecondsSinceEpoch.toString();
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
                'rentalDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              });

              Navigator.pop(context);
              fetchUsersAndRentals();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('rent_success'))),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkTheme ? Colors.blueAccent : Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(t('rent'), style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, Color textColor, Color hintTextColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintTextColor),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType:
        hint.contains("muddat") || hint.contains("Срок") ? TextInputType.number : TextInputType.text,
      ),
    );
  }
}