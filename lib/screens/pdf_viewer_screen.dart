import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../utils/secure_file_util.dart';
import '../utils/logger.dart';

class PDFViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String errorMessage = '';
  int currentPage = 0;
  int totalPages = 0;
  late PDFViewController pdfViewController;
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    downloadFile();
  }

  @override
  void dispose() {
    // Clean up temporary file when done
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    if (_pdfFile != null && await _pdfFile!.exists()) {
      try {
        await SecureFileUtil.secureDelete(_pdfFile!.path);
        AppLogger.info('Temporary PDF file deleted: ${_pdfFile!.path}');
      } catch (e) {
        AppLogger.error('Failed to delete temporary PDF file', e);
      }
    }
  }

  Future<void> downloadFile() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Clean up previous file if exists
      await _cleanupTempFile();
      
      // Get filename from URL
      final fileName = widget.url.split('/').last;
      
      // Download file securely
      _pdfFile = await SecureFileUtil.secureDownload(widget.url, fileName);
      
      setState(() {
        localPath = _pdfFile!.path;
        isLoading = false;
      });
      
      AppLogger.info('PDF downloaded securely: ${_pdfFile!.path}');
    } catch (e) {
      AppLogger.error('Error loading PDF', e);
      setState(() {
        errorMessage = 'Error loading PDF: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: downloadFile,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality to be implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (errorMessage.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: downloadFile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            PDFView(
              filePath: localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              defaultPage: currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                setState(() {
                  totalPages = pages!;
                });
              },
              onError: (error) {
                setState(() {
                  errorMessage = error.toString();
                });
                AppLogger.error('PDF render error', error);
              },
              onPageError: (page, error) {
                setState(() {
                  errorMessage = 'Error loading page $page: $error';
                });
                AppLogger.error('PDF page error on page $page', error);
              },
              onViewCreated: (PDFViewController viewController) {
                setState(() {
                  pdfViewController = viewController;
                });
              },
              onPageChanged: (page, total) {
                setState(() {
                  currentPage = page!;
                  totalPages = total!;
                });
              },
            ),
          
          // Page indicator
          if (!isLoading && errorMessage.isEmpty && totalPages > 0)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Page ${currentPage + 1} of $totalPages',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 