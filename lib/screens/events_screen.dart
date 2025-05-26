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
  String _categoryFilter = '';
  DateTime? _dateFilter;
  int _adCounter = 0;
  bool _isLoading = false;
  RewardedAd? _rewardedAd;
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadSavedEvents();
    _loadAdCounter();
    _initRewardedAd();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await _apiService.getEvents();
    setState(() {
      _allEvents = events;
      _isLoading = false;
    });
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
      final matchesCategory = _categoryFilter.isEmpty || (event.category?.toLowerCase().contains(_categoryFilter.toLowerCase()) ?? false);
      final matchesDate = _dateFilter == null || (event.date.year == _dateFilter!.year && event.date.month == _dateFilter!.month && event.date.day == _dateFilter!.day);
      return matchesCategory && matchesDate;
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
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Category'),
                          onChanged: (v) => setState(() => _categoryFilter = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => _dateFilter = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date'),
                            child: Text(_dateFilter == null ? 'Any' : DateFormat('yyyy-MM-dd').format(_dateFilter!)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear filters',
                        onPressed: () => setState(() {
                          _categoryFilter = '';
                          _dateFilter = null;
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredEvents.isEmpty
                          ? const Center(child: Text('No events available.'))
                          : ListView.builder(
                              itemCount: _filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = _filteredEvents[index];
                                final isSaved = _savedEvents.any((se) => se.event.id == event.id);
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    title: Text(event.title),
                                    subtitle: Text(DateFormat('yyyy-MM-dd').format(event.date)),
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
              ],
            ),
            // Saved Events Tab
            _savedEvents.isEmpty
                ? const Center(child: Text('No saved events.'))
                : ListView.builder(
                    itemCount: _savedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _savedEvents[index].event;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(event.title),
                          subtitle: Text(DateFormat('yyyy-MM-dd').format(event.date)),
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
      appBar: AppBar(title: Text(event.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Date: ${DateFormat('yyyy-MM-dd').format(event.date)}'),
            if (event.category != null) Text('Category: ${event.category}'),
            if (event.location != null) Text('Location: ${event.location}'),
            const SizedBox(height: 16),
            if (event.description != null) Text(event.description!),
            if (event.link != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Share.share(event.link!),
                child: const Text('Open/Share Link'),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 