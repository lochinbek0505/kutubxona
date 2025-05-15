import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'local_user_service.dart';

class EditBookPage extends StatefulWidget {
  var data;

  EditBookPage({super.key, required this.data});

  @override
  State<EditBookPage> createState() => _UploadBookPageState();
}

class _UploadBookPageState extends State<EditBookPage> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final descriptionController = TextEditingController();
  String category = 'Badiiy';
  String status = 'public';
  File? selectedFile;
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

  String t(String uz, String ru) => language == 'ru' ? ru : uz;

  getId() async {
    var data = await LocalUserService.getUser();
    userId = data!["userId"]!;
    setState(() {});
  }

  List<String> selectedUserIds = [];

  InputDecoration _glassInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
      filled: true,
      fillColor: isDarkTheme ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Future<void> _uploadBook() async {
    if (titleController.text.isEmpty || authorController.text.isEmpty) return;

    try {
      setState(() => isLoading = true);

      final bookData = {
        'title': titleController.text.trim(),
        'author': authorController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': category,
        'status': status,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final dbRef = FirebaseDatabase.instance
          .ref()
          .child('books')
          .child(widget.data['bookId']);
      await dbRef.update(bookData);

      if (status == 'private') {
        await dbRef.child('allowedUsers').remove();
        await dbRef.child('allowedUsers').set({
          for (var id in selectedUserIds) id: true,
        });
      }

      setState(() {
        isLoading = false;
        Navigator.pop(context);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Kitob muvaffaqiyatli tahrirlandi', 'Книга успешно отредактирована'))),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${t('Xatolik', 'Ошибка')}: $e')));
    }
  }

  Future<void> _showUserSelectionDialog() async {
    final usersSnapshot =
    await FirebaseDatabase.instance.ref().child('users').get();
    final Map<dynamic, dynamic>? usersData = usersSnapshot.value as Map?;

    if (usersData == null) return;

    final tempSelected = [...selectedUserIds];

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(t('Foydalanuvchilarni tanlang', 'Выберите пользователей')),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView(
                  children: usersData.entries.map((entry) {
                    final userId = entry.key;
                    final name = entry.value['name'] ?? 'Noma’lum';
                    final isSelected = tempSelected.contains(userId);

                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(name),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            tempSelected.add(userId);
                          } else {
                            tempSelected.remove(userId);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => selectedUserIds = tempSelected);
                Navigator.of(context).pop();
              },
              child: Text(t('Tanlash', 'Выбрать')),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getId();
    loadPreferences();

    titleController.text = widget.data['title'];
    authorController.text = widget.data['author'];
    descriptionController.text = widget.data['description'];
    category = widget.data['category'];
    status = widget.data['status'];

    if (widget.data['allowedUsers'] != null) {
      final allowedUsersMap = widget.data['allowedUsers'] as Map<dynamic, dynamic>;
      selectedUserIds = allowedUsersMap.keys.map((e) => e.toString()).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkTheme ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          t('Kitob Tahrirlash', 'Редактирование книги'),
          style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              decoration: _glassInputDecoration(t("Kitob nomi", "Название книги")),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: authorController,
              style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              decoration: _glassInputDecoration(t("Muallif", "Автор")),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              maxLines: 4,
              decoration: _glassInputDecoration(t("Tavsif", "Описание")),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: category,
              dropdownColor: isDarkTheme ? Colors.blueGrey.shade900 : Colors.white,
              style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              decoration: _glassInputDecoration(t("Kategoriya", "Категория")),
              items: [
                DropdownMenuItem(value: 'Badiiy', child: Text(t("Badiiy", "Художественная"))),
                DropdownMenuItem(value: 'Darslik', child: Text(t("Darslik", "Учебник"))),
              ],
              onChanged: (val) => setState(() => category = val!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: status,
              dropdownColor: isDarkTheme ? Colors.blueGrey.shade900 : Colors.white,
              style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              decoration: _glassInputDecoration(t("Holat", "Статус")),
              items: [
                DropdownMenuItem(value: 'public', child: Text("🔓 ${t('Ochiq', 'Открытый')}")),
                DropdownMenuItem(value: 'private', child: Text("🔒 ${t('Maxfiy', 'Приватный')}")),
              ],
              onChanged: (val) => setState(() => status = val!),
            ),
            if (status == 'private') ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showUserSelectionDialog,
                child: Text(t("Foydalanuvchilarni tanlash", "Выбрать пользователей")),
              ),
              if (selectedUserIds.isNotEmpty)
                Text(
                  "${selectedUserIds.length} ${t("foydalanuvchi tanlangan", "пользователей выбрано")}",
                  style: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _uploadBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent[700],
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                t("Kitobni tahrirlash", "Редактировать книгу"),
                style: GoogleFonts.poppins(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
