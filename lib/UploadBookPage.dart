import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

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

  // private uchun tanlangan user IDlari
  List<String> selectedUserIds = [];

  Future<void> requestStoragePermission() async {
    await Permission.storage.request();
  }

  InputDecoration _glassInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }

  Future<void> _uploadBook() async {
    if (selectedFile == null || titleController.text.isEmpty || authorController.text.isEmpty) return;

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
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Realtime DB saqlash
      final dbRef = FirebaseDatabase.instance.ref().child('books').child(bookId);
      await dbRef.set(bookData);

      // Agar private bo‘lsa allowedUsers ga yozamiz
      if (status == 'private') {
        await dbRef.child('allowedUsers').set({for (var id in selectedUserIds) id: true});
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
        const SnackBar(content: Text('Kitob muvaffaqiyatli yuklandi')),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
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
          title: const Text('Foydalanuvchilarni tanlang'),
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
              child: const Text('Tanlash'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Kitob Yuklash', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _glassInputDecoration("Kitob nomi"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: authorController,
              style: const TextStyle(color: Colors.white),
              decoration: _glassInputDecoration("Muallif"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: _glassInputDecoration("Tavsif"),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: category,
              dropdownColor: Colors.blueGrey.shade900,
              style: const TextStyle(color: Colors.white),
              decoration: _glassInputDecoration("Kategoriya"),
              items: const [
                DropdownMenuItem(value: 'Badiiy', child: Text("Badiiy")),
                DropdownMenuItem(value: 'Darslik', child: Text("Darslik")),
              ],
              onChanged: (val) => setState(() => category = val!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: status,
              dropdownColor: Colors.blueGrey.shade900,
              style: const TextStyle(color: Colors.white),
              decoration: _glassInputDecoration("Holat (status)"),
              items: const [
                DropdownMenuItem(value: 'public', child: Text("🔓 Ochiq")),
                DropdownMenuItem(value: 'private', child: Text("🔒 Maxfiy")),
              ],
              onChanged: (val) => setState(() => status = val!),
            ),
            if (status == 'private') ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showUserSelectionDialog,
                child: const Text("Foydalanuvchilarni tanlash"),
              ),
              if (selectedUserIds.isNotEmpty)
                Text("${selectedUserIds.length} foydalanuvchi tanlangan", style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await requestStoragePermission();
                _pickPdf();
              },
              icon: const Icon(Icons.upload_file),
              label: Text(
                selectedFile == null
                    ? "PDF tanlang"
                    : "Tanlangan fayl: ${selectedFile!.path.split('/').last}",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _uploadBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent[700],
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Kitobni yuklash", style: GoogleFonts.poppins(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
