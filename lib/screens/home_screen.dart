import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'news_list_screen.dart';
import 'job_list_screen.dart';
import 'events_screen.dart' as events;
import 'privacy_screen.dart';
import 'tech_picks_screen.dart';
import 'job_detail_screen.dart';
import 'event_detail_screen.dart';
import 'news_detail_screen.dart';
import 'entrance_exams_screen.dart';
import '../models/tech_pick.dart';
import '../models/ad_slider.dart';
import '../models/job.dart';
import '../models/event.dart';
import '../models/news.dart';
import '../models/exam.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<TechPick> _techPicks = [];
  List<AdSlider> _adSliders = [];
  List<Job> _featuredJobs = [];
  List<Event> _featuredEvents = [];
  List<News> _featuredNews = [];
  List<Exam> _featuredExams = [];
  
  bool _isLoadingTechPicks = true;
  bool _isLoadingAdSliders = true;
  bool _isLoadingFeaturedJobs = true;
  bool _isLoadingFeaturedEvents = true;
  bool _isLoadingFeaturedNews = true;
  bool _isLoadingFeaturedExams = true;
  
  // For image slider
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  
  // For featured jobs animation
  late AnimationController _jobsAnimationController;
  late Animation<double> _jobsFadeAnimation;
  
  // For featured events animation
  late AnimationController _eventsAnimationController;
  late Animation<double> _eventsFadeAnimation;

  // For featured news animation
  late AnimationController _newsAnimationController;
  late Animation<double> _newsFadeAnimation;

  // For featured exams animation
  late AnimationController _examsAnimationController;
  late Animation<double> _examsFadeAnimation;
  
  // For latest tech picks animation
  late AnimationController _techPicksAnimationController;
  late Animation<double> _techPicksFadeAnimation;
  
  // For welcome text animation
  late AnimationController _welcomeAnimationController;
  late Animation<Offset> _welcomeSlideAnimation;
  late Animation<double> _welcomeFadeAnimation;
  
  // Fallback ad slides in case API fails
  final List<Map<String, dynamic>> _fallbackAdSlides = [
    {
      'color': Color(0xFF2563EB),
      'text': 'Kerala Tech Reach',
    },
    {
      'color': Color(0xFF10B981),
      'text': 'Student Resources',
    },
    {
      'color': Color(0xFFF59E0B),
      'text': 'Latest Events',
    },
  ];

  bool _isJobCardPressed = false;
  bool _isEventCardPressed = false;
  bool _isNewsCardPressed = false;
  bool _isExamCardPressed = false;

  @override
  void initState() {
    super.initState();
    _loadTechPicks();
    _loadAdSliders();
    _loadFeaturedJobs();
    _loadFeaturedEvents();
    _loadFeaturedNews();
    _loadFeaturedExams();
    _startAutoSlider();
    
    // Initialize animation controller
    _jobsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _jobsFadeAnimation = CurvedAnimation(
      parent: _jobsAnimationController,
      curve: Curves.easeIn,
    );
    
    // Initialize animation controller for events
    _eventsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _eventsFadeAnimation = CurvedAnimation(
      parent: _eventsAnimationController,
      curve: Curves.easeIn,
    );

    // Initialize animation controller for news
    _newsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _newsFadeAnimation = CurvedAnimation(
      parent: _newsAnimationController,
      curve: Curves.easeIn,
    );

    // Initialize animation controller for exams
    _examsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _examsFadeAnimation = CurvedAnimation(
      parent: _examsAnimationController,
      curve: Curves.easeIn,
    );
    
    // Initialize animation controller for tech picks
    _techPicksAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _techPicksFadeAnimation = CurvedAnimation(
      parent: _techPicksAnimationController,
      curve: Curves.easeIn,
    );
    
    // Initialize animation controller for welcome text
    _welcomeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
     _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5), // Start slightly below original position
      end: Offset.zero, // End at original position
    ).animate(CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOut,
    ));
    _welcomeFadeAnimation = CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeIn,
    );
    
    // Start animation after data is loaded (or if already loaded)
    if (!_isLoadingFeaturedJobs) {
      _jobsAnimationController.forward();
    }
     if (!_isLoadingFeaturedEvents) {
      _eventsAnimationController.forward();
    }
     if (!_isLoadingFeaturedNews) {
      _newsAnimationController.forward();
    }
     if (!_isLoadingFeaturedExams) {
      _examsAnimationController.forward();
    }
    if (!_isLoadingTechPicks) {
      _techPicksAnimationController.forward();
    }
    
    // Start welcome text animation
    _welcomeAnimationController.forward();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _jobsAnimationController.dispose(); // Dispose the controller
    _eventsAnimationController.dispose(); // Dispose the controller
    _newsAnimationController.dispose(); // Dispose the controller
    _examsAnimationController.dispose(); // Dispose the controller
    _techPicksAnimationController.dispose(); // Dispose the controller
    _welcomeAnimationController.dispose(); // Dispose the controller
    super.dispose();
  }
  
  void _startAutoSlider() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_adSliders.isNotEmpty) {
        if (_currentPage < _adSliders.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
      } else {
        if (_currentPage < _fallbackAdSlides.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  Future<void> _loadTechPicks() async {
    try {
      final picks = await _apiService.getTechPicks();
      setState(() {
        _techPicks = picks;
        _isLoadingTechPicks = false;
      });
      _techPicksAnimationController.forward(); // Start animation after loading
    } catch (e) {
      setState(() {
        _isLoadingTechPicks = false;
      });
      print('Error loading tech picks: $e');
    }
  }
  
  Future<void> _loadAdSliders() async {
    try {
      final sliders = await _apiService.getAdSliders();
      setState(() {
        _adSliders = sliders;
        _isLoadingAdSliders = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAdSliders = false;
      });
      print('Error loading ad sliders: $e');
    }
  }
  
  Future<void> _loadFeaturedJobs() async {
    try {
      final jobs = await _apiService.getFeaturedJobs();
      setState(() {
        _featuredJobs = jobs;
        _isLoadingFeaturedJobs = false;
      });
      _jobsAnimationController.forward(); // Start animation after loading
    } catch (e) {
      setState(() {
        _isLoadingFeaturedJobs = false;
      });
      print('Error loading featured jobs: $e');
    }
  }
  
  Future<void> _loadFeaturedEvents() async {
    try {
      final events = await _apiService.getFeaturedEvents();
      setState(() {
        _featuredEvents = events;
        _isLoadingFeaturedEvents = false;
      });
      _eventsAnimationController.forward(); // Start animation after loading
    } catch (e) {
      setState(() {
        _isLoadingFeaturedEvents = false;
      });
      print('Error loading featured events: $e');
    }
  }
  
  Future<void> _loadFeaturedNews() async {
    try {
      final news = await _apiService.getFeaturedNews();
      setState(() {
        _featuredNews = news;
        _isLoadingFeaturedNews = false;
      });
      _newsAnimationController.forward(); // Start animation after loading
    } catch (e) {
      setState(() {
        _isLoadingFeaturedNews = false;
      });
      print('Error loading featured news: $e');
    }
  }
  
  Future<void> _loadFeaturedExams() async {
    try {
      final exams = await _apiService.getFeaturedExams();
      setState(() {
        _featuredExams = exams;
        _isLoadingFeaturedExams = false;
      });
      _examsAnimationController.forward(); // Start animation after loading
    } catch (e) {
      setState(() {
        _isLoadingFeaturedExams = false;
      });
      print('Error loading featured exams: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kerala Tech Reach'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoadingTechPicks = true;
            _isLoadingAdSliders = true;
            _isLoadingFeaturedJobs = true;
            _isLoadingFeaturedEvents = true;
            _isLoadingFeaturedNews = true;
            _isLoadingFeaturedExams = true;
          });
          await Future.wait([
            _loadTechPicks(),
            _loadAdSliders(),
            _loadFeaturedJobs(),
            _loadFeaturedEvents(),
            _loadFeaturedNews(),
            _loadFeaturedExams(),
          ]);
        },
        child: ListView(
          children: [
            // Ad Slider
            _buildAdSlider(),
            
            const SizedBox(height: 16.0),

            SlideTransition(
              position: _welcomeSlideAnimation,
              child: FadeTransition(
                opacity: _welcomeFadeAnimation,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                'Welcome to Kerala Tech Reach',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // Featured Jobs Section
            if (_featuredJobs.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              _buildFeaturedJobsSection(),
            ],
            
            // Featured Events Section
            if (_featuredEvents.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              _buildFeaturedEventsSection(),
            ],
            
            // Featured News Section
            if (_featuredNews.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              _buildFeaturedNewsSection(),
            ],
            
            // Featured Exams Section
            if (_featuredExams.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              _buildFeaturedExamsSection(),
            ],
            
            // Latest Tech from Affiliate Marketing
            const SizedBox(height: 16.0),
            _buildLatestTechSection(),

            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildAdSlider() {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: _isLoadingAdSliders
              ? const Center(child: CircularProgressIndicator())
              : AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    return PageView.builder(
                  controller: _pageController,
                  itemCount: _adSliders.isNotEmpty ? _adSliders.length : _fallbackAdSlides.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    if (_adSliders.isNotEmpty) {
                      final adSlider = _adSliders[index];
                          // Calculate scale based on how close the page is to the center
                          double scale = 1.0;
                          if (_pageController.hasClients && _pageController.position.haveDimensions) {
                             double page = _pageController.page ?? 0;
                             scale = 1.0 - ((page - index).abs() * 0.2); // Adjust 0.2 for desired effect intensity
                             scale = scale.clamp(0.8, 1.0); // Clamp scale to prevent distortion
                          }
                          return Transform.scale(
                            scale: scale,
                            child: GestureDetector(
                        onTap: () async {
                          if (adSlider.linkUrl != null && adSlider.linkUrl!.isNotEmpty) {
                            if (await canLaunch(adSlider.linkUrl!)) {
                              await launch(adSlider.linkUrl!);
                            }
                          }
                        },
                        child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color(int.parse(adSlider.backgroundColor.replaceFirst('#', '0xFF'))),
                            image: adSlider.imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(adSlider.imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: adSlider.imageUrl.isEmpty
                              ? Center(
                                  child: Text(
                                    adSlider.title,
                                    style: TextStyle(
                                      color: Color(int.parse(adSlider.textColor.replaceFirst('#', '0xFF'))),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                              ),
                        ),
                      );
                    } else {
                          // Calculate scale based on how close the page is to the center
                          double scale = 1.0;
                          if (_pageController.hasClients && _pageController.position.haveDimensions) {
                             double page = _pageController.page ?? 0;
                             scale = 1.0 - ((page - index).abs() * 0.2); // Adjust 0.2 for desired effect intensity
                             scale = scale.clamp(0.8, 1.0); // Clamp scale to prevent distortion
                          }
                          return Transform.scale(
                             scale: scale,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: _fallbackAdSlides[index]['color'],
                        ),
                        child: Center(
                          child: Text(
                            _fallbackAdSlides[index]['text'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      );
                    }
                      },
                    );
                  },
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _adSliders.isNotEmpty ? _adSliders.length : _fallbackAdSlides.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 20 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeaturedJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Jobs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const JobListScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('View All'),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        _isLoadingFeaturedJobs
            ? const Center(child: CircularProgressIndicator())
            : _featuredJobs.isEmpty
                ? const Center(child: Text('No featured jobs available'))
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _featuredJobs.length > 3 ? 3 : _featuredJobs.length,
                itemBuilder: (context, index) {
                  final job = _featuredJobs[index];
                      return FadeTransition(
                        opacity: _jobsFadeAnimation,
                        child: _buildJobCard(job),
                      );
                    },
                  ),
      ],
    );
  }
  
  // New helper widget to build a custom job card
  Widget _buildJobCard(Job job) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isJobCardPressed = true),
      onTapUp: (_) => setState(() => _isJobCardPressed = false),
      onTapCancel: () => setState(() => _isJobCardPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(jobId: job.id),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isJobCardPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                      ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Last Date: ${DateFormat('MMM dd, yyyy').format(job.lastDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
                    ),
        ),
              ),
    );
  }
  
  Widget _buildFeaturedEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const events.EventsScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('View All'),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        _isLoadingFeaturedEvents
            ? const Center(child: CircularProgressIndicator())
            : _featuredEvents.isEmpty
                ? const Center(child: Text('No upcoming events available'))
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _featuredEvents.length > 3 ? 3 : _featuredEvents.length,
                itemBuilder: (context, index) {
                  final event = _featuredEvents[index];
                      return FadeTransition(
                        opacity: _eventsFadeAnimation,
                        child: _buildEventCard(event),
                      );
                    },
                  ),
      ],
    );
  }
  
  // New helper widget to build a custom event card
  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isEventCardPressed = true),
      onTapUp: (_) => setState(() => _isEventCardPressed = false),
      onTapCancel: () => setState(() => _isEventCardPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(eventId: event.id),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isEventCardPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                      ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        event.location ?? 'No location specified',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
                    ),
        ),
              ),
    );
  }
  
  Widget _buildFeaturedNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest News',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewsListScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('View All'),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        _isLoadingFeaturedNews
            ? const Center(child: CircularProgressIndicator())
            : _featuredNews.isEmpty
                ? const Center(child: Text('No featured news available'))
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _featuredNews.length > 3 ? 3 : _featuredNews.length,
                itemBuilder: (context, index) {
                  final news = _featuredNews[index];
                      return FadeTransition(
                        opacity: _newsFadeAnimation,
                        child: _buildNewsCard(news),
                      );
                    },
                  ),
      ],
    );
  }

  // New helper widget to build a custom news card
  Widget _buildNewsCard(News news) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isNewsCardPressed = true),
      onTapUp: (_) => setState(() => _isNewsCardPressed = false),
      onTapCancel: () => setState(() => _isNewsCardPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailScreen(newsSlug: news.slug ?? ''),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isNewsCardPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                      ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        DateFormat('MMM dd, yyyy').format(news.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
                    ),
        ),
              ),
    );
  }

  Widget _buildFeaturedExamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Exams',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EntranceExamsScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('View All'),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        _isLoadingFeaturedExams
            ? const Center(child: CircularProgressIndicator())
            : _featuredExams.isEmpty
                ? const Center(child: Text('No featured exams available'))
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _featuredExams.length > 3 ? 3 : _featuredExams.length,
                itemBuilder: (context, index) {
                  final exam = _featuredExams[index];
                      return FadeTransition(
                        opacity: _examsFadeAnimation,
                        child: _buildExamCard(exam),
                      );
                    },
                  ),
      ],
    );
  }

  // New helper widget to build a custom exam card
  Widget _buildExamCard(Exam exam) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isExamCardPressed = true),
      onTapUp: (_) => setState(() => _isExamCardPressed = false),
      onTapCancel: () => setState(() => _isExamCardPressed = false),
                      onTap: () async {
                        // Open the exam URL if available
                        if (exam.examUrl.isNotEmpty) {
                          if (await canLaunch(exam.examUrl)) {
                            await launch(exam.examUrl);
                          }
                        }
                      },
      child: AnimatedScale(
        scale: _isExamCardPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.examName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(exam.examDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
              ),
      ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLatestTechSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            'Latest Tech Picks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _isLoadingTechPicks
            ? const Center(child: CircularProgressIndicator())
            : _techPicks.isEmpty
                ? const Center(child: Text('No tech picks available'))
                : SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _techPicks.length > 5 ? 5 : _techPicks.length,
                      itemBuilder: (context, index) {
                        final pick = _techPicks[index];
                        return FadeTransition(
                          opacity: _techPicksFadeAnimation,
                          child: _buildTechPickCard(pick),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildTechPickCard(TechPick pick) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunch(pick.affiliateUrl)) {
          await launch(pick.affiliateUrl);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                child: pick.imageUrl != null && pick.imageUrl!.isNotEmpty
                    ? Image.network(
                        pick.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.devices_other, size: 40, color: Colors.grey),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pick.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${pick.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 