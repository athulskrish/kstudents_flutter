import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class JobListProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Job> _jobs = [];
  List<Job> get jobs => _jobs;

  final List<Job> _savedJobs = [];
  List<Job> get savedJobs => _savedJobs;

  String _roleFilter = '';
  String get roleFilter => _roleFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _showSavedJobs = false;
  bool get showSavedJobs => _showSavedJobs;

  void toggleShowSavedJobs() {
    _showSavedJobs = !_showSavedJobs;
    if (!_showSavedJobs) {
      _roleFilter = '';
    }
    notifyListeners();
  }

  // Ad logic
  int _adCounter = 0;
  int get adCounter => _adCounter;
  void updateAdCounter(int value) {
    _adCounter = value;
    notifyListeners();
  }

  RewardedAd? _rewardedAd;
  RewardedAd? get rewardedAd => _rewardedAd;
  void updateRewardedAd(RewardedAd? ad) {
    _rewardedAd = ad;
    notifyListeners();
  }

  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  void initRewardedAd() {
    RewardedAd.load(
      adUnitId: _testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => updateRewardedAd(ad),
        onAdFailedToLoad: (error) => updateRewardedAd(null),
      ),
    );
  }

  Future<void> fetchJobs() async {
    _isLoading = true;
    notifyListeners();
    try {
      _jobs = await _apiService.getJobs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRoleFilter(String filter) {
    _roleFilter = filter;
    notifyListeners();
  }

  List<Job> get filteredJobs {
    if (_showSavedJobs) {
      return _savedJobs;
    } else {
      if (_roleFilter.isEmpty) return _jobs;
      return _jobs.where((job) => job.title.toLowerCase().contains(_roleFilter.toLowerCase())).toList();
    }
  }

  void saveJob(Job job) {
    if (!_savedJobs.contains(job)) {
      _savedJobs.add(job);
      notifyListeners();
    }
  }

  void removeSavedJob(Job job) {
    _savedJobs.remove(job);
    notifyListeners();
  }
} 