import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({super.key, required this.pdfUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark background
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B), // Dark AppBar
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        canShowScrollStatus: false,
        canShowPaginationDialog: false,
        canShowScrollHead: false,
        enableDocumentLinkAnnotation: true,
        currentSearchTextHighlightColor: Colors.tealAccent.withOpacity(0.3),
        otherSearchTextHighlightColor: Colors.teal.withOpacity(0.15),
      ),
    );
  }
}
