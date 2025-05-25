import 'package:flutter/material.dart';
import '../models/faq.dart';
import '../services/api_service.dart';

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
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    final faqs = await _apiService.getFaqs();
    setState(() {
      _faqs = faqs;
      _filtered = faqs;
      _isLoading = false;
    });
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
          : Column(
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
            ),
    );
  }
} 