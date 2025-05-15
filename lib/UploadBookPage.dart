import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_user_service.dart';

class UploadBookPage extends StatefulWidget {
  const UploadBookPage({super.key});

  @override
  State<UploadBookPage> createState() => _UploadBookPageState();
}

class _UploadBookPageState extends State<UploadBookPage> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final descriptionController = TextEditingController();
  String category = 'Badiiy';
  String status = 'public';
  File? selectedFile;
  bool isLoading = false;
  var userId = '';
  String _language = 'uz';
  bool _isDarkTheme = false;

  // Localization texts
  final Map<String, Map<String, String>> translations = {
    'page_title': {
      'uz': "Kitob Yuklash",
      'ru': "Загрузка книги",
    },
    'book_title': {
      'uz': "Kitob nomi",
      'ru': "Название книги",
    },
    'author': {
      'uz': "Muallif",
      'ru': "Автор",
    },
    'description': {
      'uz': "Tavsif",
      'ru': "Описание",
    },
    'category': {
      'uz': "Kategoriya",
      'ru': "Категория",
    },
    'status': {
      'uz': "Holat (status)",
      'ru': "Статус",
    },
    'public': {
      'uz': "🔓 Ochiq",
      'ru': "🔓 Публичный",
    },
    'private': {
      'uz': "🔒 Maxfiy",
      'ru': "🔒 Приватный",
    },
    'select_users': {
      'uz': "Foydalanuvchilarni tanlash",
      'ru': "Выбрать пользователей",
    },
    'users_selected': {
      'uz': "foydalanuvchi tanlangan",
      'ru': "пользователей выбрано",
    },
    'select_pdf': {
      'uz': "PDF tanlang",
      'ru': "Выберите PDF",
    },
    'selected_file': {
      'uz': "Tanlangan fayl:",
      'ru': "Выбранный файл:",
    },
    'upload_button': {
      'uz': "Kitobni yuklash",
      'ru': "Загрузить книгу",
    },
    'success_message': {
      'uz': "Kitob muvaffaqiyatli yuklandi",
      'ru': "Книга успешно загружена",
    },
    'error_message': {
      'uz': "Xatolik:",
      'ru': "Ошибка:",
    },
    'fiction': {
      'uz': "Badiiy",
      'ru': "Художественная",
    },
    'textbook': {
      'uz': "Darslik",
      'ru': "Учебник",
    },
    'select_users_dialog_title': {
      'uz': "Foydalanuvchilarni tanlang",
      'ru': "Выберите пользователей",
    },
    'select_button': {
      'uz': "Tanlash",
      'ru': "Выбрать",
    },
    'unknown_user': {
      'uz': "Noma'lum",
      'ru': "Неизвестно",
    },
  };

  String t(String key) => translations[key]?[_language] ?? key;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'uz';
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    await prefs.setBool('isDarkTheme', _isDarkTheme);
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    getId();
  }

  getId() async {
    var data = await LocalUserService.getUser();
    userId = data!["userId"]!;
    setState(() {});
  }

  List<String> selectedUserIds = [];

  Future<void> requestStoragePermission() async {
    await Permission.storage.request();
  }

  InputDecoration _inputDecoration(String hint) {
    final textColor = _isDarkTheme ? Colors.white : Colors.black87;
    final cardColor = _isDarkTheme ? Colors.white.withOpacity(0.07) : Colors.grey[200];

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _uploadBook() async {
    if (selectedFile == null ||
        titleController.text.isEmpty ||
        authorController.text.isEmpty) return;

    try {
      setState(() => isLoading = true);

      final bookId = const Uuid().v4();
      final storageRef = FirebaseStorage.instance.ref().child('books/$bookId.pdf');
      await storageRef.putFile(selectedFile!);
      final pdfUrl = await storageRef.getDownloadURL();

      final bookData = {
        'bookId': bookId,
        'title': titleController.text.trim(),
        'author': authorController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': category,
        'status': status,
        'pdfUrl': pdfUrl,
        'authorId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final dbRef = FirebaseDatabase.instance.ref().child('books').child(bookId);
      await dbRef.set(bookData);

      if (status == 'private') {
        await dbRef.child('allowedUsers').set({
          for (var id in selectedUserIds) id: true,
        });
      }

      setState(() {
        isLoading = false;
        titleController.clear();
        authorController.clear();
        descriptionController.clear();
        selectedFile = null;
        selectedUserIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('success_message'))),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('error_message')} $e')),
      );
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _showUserSelectionDialog() async {
    final usersSnapshot = await FirebaseDatabase.instance.ref().child('users').get();
    final Map<dynamic, dynamic>? usersData = usersSnapshot.value as Map?;
    if (usersData == null) return;

    final tempSelected = [...selectedUserIds];

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(t('select_users_dialog_title')),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView(
                  children: usersData.entries.map((entry) {
                    final userId = entry.key;
                    final name = entry.value['name'] ?? t('unknown_user');
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
              child: Text(t('select_button')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkTheme ? const Color(0xFF0F172A) : Colors.white;
    final textColor = _isDarkTheme ? Colors.white : Colors.black87;
    final cardColor = _isDarkTheme ? Colors.white.withOpacity(0.07) : Colors.grey[200];
    final dropdownColor = _isDarkTheme ? Colors.blueGrey.shade900 : Colors.white;
    final accentColor = const Color(0xFF22C55E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          t('page_title'),
          style: GoogleFonts.poppins(color: textColor),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              style: GoogleFonts.poppins(color: textColor),
              decoration: _inputDecoration(t('book_title')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: authorController,
              style: GoogleFonts.poppins(color: textColor),
              decoration: _inputDecoration(t('author')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descriptionController,
              style: GoogleFonts.poppins(color: textColor),
              maxLines: 4,
              decoration: _inputDecoration(t('description')),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: category,
              dropdownColor: dropdownColor,
              style: GoogleFonts.poppins(color: textColor),
              decoration: _inputDecoration(t('category')),
              items: [
                DropdownMenuItem(
                  value: 'Badiiy',
                  child: Text(t('fiction')),
                ),
                DropdownMenuItem(
                  value: 'Darslik',
                  child: Text(t('textbook')),
                ),
              ],
              onChanged: (val) => setState(() => category = val!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: status,
              dropdownColor: dropdownColor,
              style: GoogleFonts.poppins(color: textColor),
              decoration: _inputDecoration(t('status')),
              items: [
                DropdownMenuItem(
                  value: 'public',
                  child: Text(t('public')),
                ),
                DropdownMenuItem(
                  value: 'private',
                  child: Text(t('private')),
                ),
              ],
              onChanged: (val) => setState(() => status = val!),
            ),
            if (status == 'private') ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showUserSelectionDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(t('select_users')),
              ),
              if (selectedUserIds.isNotEmpty)
                Text(
                  "${selectedUserIds.length} ${t('users_selected')}",
                  style: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await requestStoragePermission();
                _pickPdf();
              },
              icon: Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                selectedFile == null
                    ? t('select_pdf')
                    : "${t('selected_file')} ${selectedFile!.path.split('/').last}",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _uploadBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  t('upload_button'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}