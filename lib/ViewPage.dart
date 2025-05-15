import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String language = 'uz';
  bool isDarkTheme = false;

  // Localization texts
  final Map<String, Map<String, String>> translations = {
    'back_button': {
      'uz': "Orqaga",
      'ru': "Назад",
    },
  };

  String t(String key) => translations[key]?[language] ?? key;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('language') ?? 'uz';
      isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
    });
  }

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkTheme ? const Color(0xFF0F172A) : Colors.white;
    final appBarColor = isDarkTheme ? const Color(0xFF1E293B) : Colors.blueGrey;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    final iconColor = isDarkTheme ? Colors.white : Colors.black87;
    final highlightColor = isDarkTheme ? Colors.tealAccent : Colors.blueAccent;
    final secondaryHighlightColor = isDarkTheme ? Colors.teal : Colors.blue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(color: textColor),
        ),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: iconColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: t('back_button'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDarkTheme', !isDarkTheme);
              setState(() {
                isDarkTheme = !isDarkTheme;
              });
            },
            tooltip: isDarkTheme
                ? (language == 'ru' ? "Светлая тема" : "Yorqin mavzu")
                : (language == 'ru' ? "Темная тема" : "Qorong'i mavzu"),
          ),
        ],
      ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
        canShowScrollStatus: false,
        canShowPaginationDialog: false,
        canShowScrollHead: false,
        enableDocumentLinkAnnotation: true,
        currentSearchTextHighlightColor: highlightColor.withOpacity(0.3),
        otherSearchTextHighlightColor: secondaryHighlightColor.withOpacity(0.15),
      ),
    );
  }
}