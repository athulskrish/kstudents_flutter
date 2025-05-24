import 'package:flutter/material.dart';
import '../models/tech_pick.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TechPicksScreen extends StatefulWidget {
  const TechPicksScreen({Key? key}) : super(key: key);

  @override
  State<TechPicksScreen> createState() => _TechPicksScreenState();
}

class _TechPicksScreenState extends State<TechPicksScreen> {
  final ApiService _apiService = ApiService();
  List<TechPick> _allPicks = [];
  List<TechPick> _filtered = [];
  List<String> _categories = [];
  String? _selectedCategory;
  double? _maxBudget;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTechPicks();
    _loadCategories();
  }

  Future<void> _loadTechPicks() async {
    final picks = await _apiService.getTechPicks();
    setState(() {
      _allPicks = picks;
      _filtered = picks;
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    final cats = await _apiService.getTechPickCategories();
    setState(() => _categories = cats);
  }

  void _filter() {
    setState(() {
      _filtered = _allPicks.where((p) {
        final matchesCategory = _selectedCategory == null || p.category == _selectedCategory;
        final matchesBudget = _maxBudget == null || p.price <= _maxBudget!;
        return matchesCategory && matchesBudget;
      }).toList();
    });
  }

  void _onProductTap(TechPick pick) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pick.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pick.imageUrl != null && pick.imageUrl!.isNotEmpty)
              Center(child: Image.network(pick.imageUrl!, height: 120)),
            if (pick.description != null) ...[
              const SizedBox(height: 8),
              Text(pick.description!),
            ],
            const SizedBox(height: 8),
            Text('Price: ₹${pick.price.toStringAsFixed(2)}'),
            if (pick.rating != null) Text('Rating: ${pick.rating}'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buy / View'),
              onPressed: () async {
                if (await canLaunch(pick.affiliateUrl)) {
                  await launch(pick.affiliateUrl);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Tech Picks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top slider (show first 5 featured products)
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _allPicks.length > 5 ? 5 : _allPicks.length,
                    itemBuilder: (context, index) {
                      final pick = _allPicks[index];
                      return GestureDetector(
                        onTap: () => _onProductTap(pick),
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          child: SizedBox(
                            width: 160,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (pick.imageUrl != null && pick.imageUrl!.isNotEmpty)
                                  Image.network(pick.imageUrl!, height: 100),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    pick.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Text('₹${pick.price.toStringAsFixed(0)}'),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('Category'),
                          isExpanded: true,
                          items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (cat) {
                            setState(() => _selectedCategory = cat);
                            _filter();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<double>(
                          value: _maxBudget,
                          hint: const Text('Budget'),
                          isExpanded: true,
                          items: [5000, 10000, 20000, 30000, 50000, 100000]
                              .map((b) => DropdownMenuItem(value: b.toDouble(), child: Text('Under ₹${b.toStringAsFixed(0)}')))
                              .toList(),
                          onChanged: (b) {
                            setState(() => _maxBudget = b);
                            _filter();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Product list
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No products found.'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final pick = _filtered[index];
                            return ListTile(
                              leading: pick.imageUrl != null && pick.imageUrl!.isNotEmpty
                                  ? Image.network(pick.imageUrl!, width: 48, height: 48, fit: BoxFit.cover)
                                  : const Icon(Icons.devices_other),
                              title: Text(pick.title),
                              subtitle: Text('₹${pick.price.toStringAsFixed(0)} | ${pick.category}${pick.rating != null ? ' | ⭐ ${pick.rating}' : ''}'),
                              onTap: () => _onProductTap(pick),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 