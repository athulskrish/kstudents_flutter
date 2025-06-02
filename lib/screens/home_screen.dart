import 'package:flutter/material.dart';
import 'question_papers_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'news_list_screen.dart';
import 'job_list_screen.dart';
import 'initiatives_screen.dart';
import 'entrance_exams_screen.dart';
import 'faq_screen.dart';
import 'privacy_screen.dart';
import 'message_us_screen.dart';
import 'tech_picks_screen.dart';
import '../models/tech_pick.dart';
import '../models/ad_slider.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<TechPick> _techPicks = [];
  List<AdSlider> _adSliders = [];
  bool _isLoadingTechPicks = true;
  bool _isLoadingAdSliders = true;
  
  // For image slider
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  
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

  @override
  void initState() {
    super.initState();
    _loadTechPicks();
    _loadAdSliders();
    _startAutoSlider();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Explore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('News'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Jobs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JobListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          // Ad Slider
          _buildAdSlider(),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Welcome to Kerala Tech Reach',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Latest Tech from Affiliate Marketing
          _buildLatestTechSection(),
        ],
      ),
    );
  }

  Widget _buildAdSlider() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: _isLoadingAdSliders
              ? const Center(child: CircularProgressIndicator())
              : PageView.builder(
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
                      return GestureDetector(
                        onTap: () async {
                          if (adSlider.linkUrl != null && adSlider.linkUrl!.isNotEmpty) {
                            if (await canLaunch(adSlider.linkUrl!)) {
                              await launch(adSlider.linkUrl!);
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      );
                    } else {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      );
                    }
                  },
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _adSliders.isNotEmpty ? _adSliders.length : _fallbackAdSlides.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestTechSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Latest Tech Picks',
            style: TextStyle(
              fontSize: 18,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: _techPicks.length > 5 ? 5 : _techPicks.length,
                      itemBuilder: (context, index) {
                        final pick = _techPicks[index];
                        return _buildTechPickCard(pick);
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
        margin: const EdgeInsets.all(8.0),
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
                        child: const Icon(Icons.devices_other, size: 40),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pick.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${pick.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
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