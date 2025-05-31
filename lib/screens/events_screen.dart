import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SavedEvent {
  final Event event;
  SavedEvent(this.event);
  Map<String, dynamic> toJson() => event.toJson();
  static SavedEvent fromJson(Map<String, dynamic> json) => SavedEvent(Event.fromJson(json));
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Event> _allEvents = [];
  List<SavedEvent> _savedEvents = [];
  List<Map<String, dynamic>> _eventCategories = [];
  List<Map<String, dynamic>> _districts = [];
  int? _categoryFilter;
  int? _districtFilter;
  DateTime? _dateFilter;
  int _adCounter = 0;
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  bool _isLoadingDistricts = false;
  String _errorMessage = '';
  RewardedAd? _rewardedAd;
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadEventCategories();
    _loadDistricts();
    _loadSavedEvents();
    _loadAdCounter();
    _initRewardedAd();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      print('DEBUG: Fetching events from API');
      final events = await _apiService.getEvents();
      print('DEBUG: Received ${events.length} events from API');
      if (events.isNotEmpty) {
        print('DEBUG: First event: ${events[0].title}, ID: ${events[0].id}, categoryId: ${events[0].categoryId}, districtId: ${events[0].districtId}');
      }
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading events: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load events: ${e.toString()}';
      });
    }
  }

  Future<void> _loadEventCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      print('DEBUG: Fetching event categories from API');
      final categories = await _apiService.getEventCategories();
      print('DEBUG: Received ${categories.length} event categories from API');
      if (categories.isNotEmpty) {
        print('DEBUG: First category: ${categories[0]['category']}, ID: ${categories[0]['id']}');
      }
      setState(() {
        _eventCategories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('DEBUG: Error loading event categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadDistricts() async {
    setState(() {
      _isLoadingDistricts = true;
    });
    try {
      print('DEBUG: Fetching districts from API');
      final districts = await _apiService.getDistricts();
      print('DEBUG: Received ${districts.length} districts from API');
      if (districts.isNotEmpty) {
        print('DEBUG: First district: ${districts[0]['name']}, ID: ${districts[0]['id']}');
      }
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      print('DEBUG: Error loading districts: $e');
      setState(() {
        _isLoadingDistricts = false;
      });
    }
  }

  Future<void> _loadSavedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_events') ?? [];
    setState(() {
      _savedEvents = saved.map((e) => SavedEvent.fromJson(json.decode(e))).toList();
    });
  }

  Future<void> _loadAdCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adCounter = prefs.getInt('event_ad_counter') ?? 0;
    });
  }

  Future<void> _saveAdCounter(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('event_ad_counter', value);
  }

  void _initRewardedAd() {
    RewardedAd.load(
      adUnitId: _testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _initRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _initRewardedAd();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {});
      _rewardedAd = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad not ready.')));
      _initRewardedAd();
    }
  }

  Future<void> _saveEvent(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_events') ?? [];
    if (!saved.any((e) => Event.fromJson(json.decode(e)).id == event.id)) {
      saved.add(json.encode(event.toJson()));
      await prefs.setStringList('saved_events', saved);
      _loadSavedEvents();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event saved!')));
    }
  }

  Future<void> _removeSavedEvent(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_events') ?? [];
    saved.removeWhere((e) => Event.fromJson(json.decode(e)).id == event.id);
    await prefs.setStringList('saved_events', saved);
    _loadSavedEvents();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event removed from saved.')));
  }

  void _shareEvent(Event event) {
    Share.share('Check out this event: ${event.title}\n${event.description ?? ''}\n${event.link ?? ''}');
  }

  List<Event> get _filteredEvents {
    return _allEvents.where((event) {
      final matchesCategory = _categoryFilter == null || event.categoryId == _categoryFilter;
      final matchesDistrict = _districtFilter == null || event.districtId == _districtFilter;
      final matchesDate = _dateFilter == null || (event.date.year == _dateFilter!.year && event.date.month == _dateFilter!.month && event.date.day == _dateFilter!.day);
      return matchesCategory && matchesDistrict && matchesDate;
    }).toList();
  }

  void _onEventTap(Event event) async {
    int newCounter = _adCounter + 1;
    if (newCounter % 5 == 0) {
      _showRewardedAd();
      newCounter = 0;
    }
    await _saveAdCounter(newCounter);
    setState(() => _adCounter = newCounter);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Events'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                _loadEvents();
                _loadEventCategories();
                _loadDistricts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing data...')),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Events'),
              Tab(text: 'Saved Events'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // All Events Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Category Dropdown
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              value: _categoryFilter,
                              hint: const Text('Select Category'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('All Categories'),
                                ),
                                ..._eventCategories.map((category) => DropdownMenuItem<int>(
                                  value: category['id'],
                                  child: Text(category['category']),
                                )).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _categoryFilter = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // District Dropdown
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Location',
                                border: OutlineInputBorder(),
                              ),
                              value: _districtFilter,
                              hint: const Text('Select Location'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('All Locations'),
                                ),
                                ..._districts.map((district) => DropdownMenuItem<int>(
                                  value: district['id'],
                                  child: Text(district['name']),
                                )).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _districtFilter = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Date Picker
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateFilter ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => _dateFilter = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(_dateFilter == null ? 'Any Date' : DateFormat('yyyy-MM-dd').format(_dateFilter!)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Clear Filters Button
                          ElevatedButton.icon(
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                            onPressed: () => setState(() {
                              _categoryFilter = null;
                              _districtFilter = null;
                              _dateFilter = null;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Display error if there is one
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredEvents.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('No events available.'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadEvents,
                                      child: const Text('Refresh'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredEvents.length,
                                itemBuilder: (context, index) {
                                  final event = _filteredEvents[index];
                                  final isSaved = _savedEvents.any((se) => se.event.id == event.id);
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      title: Text(
                                        event.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 14),
                                              const SizedBox(width: 4),
                                              Text(DateFormat('yyyy-MM-dd HH:mm').format(event.date)),
                                            ],
                                          ),
                                          if (event.location != null) Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 14),
                                              const SizedBox(width: 4),
                                              Expanded(child: Text(event.location!)),
                                            ],
                                          ),
                                          if (event.category != null) Row(
                                            children: [
                                              const Icon(Icons.category, size: 14),
                                              const SizedBox(width: 4),
                                              Text(event.category!),
                                            ],
                                          ),
                                          if (event.description != null && event.description!.isNotEmpty) 
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                event.description!.length > 100
                                                    ? '${event.description!.substring(0, 100)}...'
                                                    : event.description!,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                      onTap: () => _onEventTap(event),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                                            tooltip: isSaved ? 'Remove from saved' : 'Save event',
                                            onPressed: () => isSaved ? _removeSavedEvent(event) : _saveEvent(event),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.share),
                                            tooltip: 'Share',
                                            onPressed: () => _shareEvent(event),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
            // Saved Events Tab
            _savedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No saved events.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSavedEvents,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadSavedEvents,
                    child: ListView.builder(
                      itemCount: _savedEvents.length,
                      itemBuilder: (context, index) {
                        final event = _savedEvents[index].event;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(
                              event.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14),
                                    const SizedBox(width: 4),
                                    Text(DateFormat('yyyy-MM-dd HH:mm').format(event.date)),
                                  ],
                                ),
                                if (event.location != null) Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(event.location!)),
                                  ],
                                ),
                                if (event.category != null) Row(
                                  children: [
                                    const Icon(Icons.category, size: 14),
                                    const SizedBox(width: 4),
                                    Text(event.category!),
                                  ],
                                ),
                                if (event.description != null && event.description!.isNotEmpty) 
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      event.description!.length > 100
                                          ? '${event.description!.substring(0, 100)}...'
                                          : event.description!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _onEventTap(event),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.bookmark),
                                  tooltip: 'Remove from saved',
                                  onPressed: () => _removeSavedEvent(event),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  tooltip: 'Share',
                                  onPressed: () => _shareEvent(event),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () => Share.share('Check out this event: ${event.title}\n${event.description ?? ''}\n${event.link ?? ''}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image or placeholder
            Container(
              height: 200,
              width: double.infinity,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              child: const Center(
                child: Icon(
                  Icons.event,
                  size: 80,
                  color: Colors.white54,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date and time
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date & Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(DateFormat('EEE, MMM d, yyyy').format(event.date)),
                              Text(DateFormat('h:mm a').format(event.date)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  if (event.location != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(event.location!),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Category
                  if (event.category != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.category),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(event.category!),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  if (event.description != null) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // External links
                  if (event.link != null)
                    ElevatedButton.icon(
                      onPressed: () => Share.share(event.link!),
                      icon: const Icon(Icons.link),
                      label: const Text('Open Event Link'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  
                  if (event.link != null && event.map_link != null)
                    const SizedBox(height: 8),
                  
                  // Map link if available
                  if (event.map_link != null)
                    OutlinedButton.icon(
                      onPressed: () => Share.share(event.map_link!),
                      icon: const Icon(Icons.map),
                      label: const Text('Open Location in Map'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 