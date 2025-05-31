import 'package:flutter/material.dart';
import '../models/initiative.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class InitiativesScreen extends StatefulWidget {
  const InitiativesScreen({super.key});

  @override
  State<InitiativesScreen> createState() => _InitiativesScreenState();
}

class _InitiativesScreenState extends State<InitiativesScreen> {
  final ApiService _apiService = ApiService();
  List<Initiative> _initiatives = [];
  List<Initiative> _filtered = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadInitiatives();
  }

  Future<void> _loadInitiatives() async {
    final initiatives = await _apiService.getInitiatives();
    setState(() {
      _initiatives = initiatives;
      _filtered = initiatives;
      _isLoading = false;
    });
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _filtered = _initiatives.where((i) => i.name.toLowerCase().contains(value.toLowerCase())).toList();
    });
  }

  void _onTap(Initiative initiative) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InitiativeDetailScreen(initiative: initiative),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Government Initiatives')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Initiatives',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearch,
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No initiatives found.'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final initiative = _filtered[index];
                            return ListTile(
                              leading: initiative.photo != null && initiative.photo!.isNotEmpty
                                  ? Image.network(
                                      initiative.photo!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                    )
                                  : const Icon(Icons.flag),
                              title: Text(initiative.name),
                              subtitle: initiative.description != null && initiative.description!.isNotEmpty
                                  ? Text(initiative.description!.length > 60 ? '${initiative.description!.substring(0, 60)}...' : initiative.description!)
                                  : null,
                              onTap: () => _onTap(initiative),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class InitiativeDetailScreen extends StatelessWidget {
  final Initiative initiative;
  const InitiativeDetailScreen({super.key, required this.initiative});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(initiative.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (initiative.photo != null && initiative.photo!.isNotEmpty) ...[
              Center(
                child: Image.network(
                  initiative.photo!,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              initiative.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (initiative.description != null && initiative.description!.isNotEmpty)
              Text(initiative.description!),
            if (initiative.link != null && initiative.link!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  try {
                    _launchUrl(initiative.link!);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open link: ${e.toString()}')),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Visit Website'),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 