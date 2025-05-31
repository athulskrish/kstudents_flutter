import 'package:flutter/material.dart';
import '../models/faq.dart';
import '../services/api_service.dart';
import '../utils/app_logger.dart';
import '../utils/exceptions.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final ApiService _apiService = ApiService();
  List<FAQ> _faqs = [];
  List<FAQ> _filtered = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final faqs = await _apiService.getFaqs();
      setState(() {
        _faqs = faqs;
        _filtered = faqs;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading FAQs', e);
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e is AppException 
            ? e.message 
            : 'Failed to load FAQs. Please try again.';
      });
    }
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _filtered = _faqs.where((f) => f.question.toLowerCase().contains(value.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _buildFaqList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFaqs,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search FAQ',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearch,
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('No FAQs found.'))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final faq = _filtered[index];
                    return ExpansionTile(
                      title: Text(faq.question),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(faq.answer),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
} 