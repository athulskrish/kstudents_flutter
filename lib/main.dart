import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/events_screen.dart';
import 'screens/job_list_screen.dart';
import 'screens/question_papers_screen.dart';
import 'screens/notes_screen.dart';
import 'services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF2563EB), // Primary Blue
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF3B82F6), // Primary Blue Light
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFF10B981), // Soft Green
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF59E0B), // Warm Orange
      onSecondaryContainer: Colors.white,
      background: const Color(0xFFFAFAFA), // Main background
      onBackground: const Color(0xFF1F2937), // Main text
      surface: const Color(0xFFFFFFFF), // Card background
      onSurface: const Color(0xFF1F2937), // Main text
      error: const Color(0xFFEF4444), // Soft Red
      onError: Colors.white,
      outline: const Color(0xFFE5E7EB), // Border
      surfaceVariant: const Color(0xFFF3F4F6), // Gray Light
      onSurfaceVariant: const Color(0xFF6B7280), // Text Secondary
      tertiary: const Color(0xFFFCD34D), // Reward Gold
      onTertiary: Colors.black,
      tertiaryContainer: const Color(0xFF6366F1), // Deep Learning
      onTertiaryContainer: Colors.white,
    );
    final darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF3B82F6),
      onPrimary: Colors.black,
      primaryContainer: const Color(0xFF1D4ED8),
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFF10B981),
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFFF59E0B),
      onSecondaryContainer: Colors.black,
      background: const Color(0xFF1F2937),
      onBackground: Colors.white,
      surface: const Color(0xFF111827),
      onSurface: Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      outline: const Color(0xFF374151),
      surfaceVariant: const Color(0xFF374151),
      onSurfaceVariant: const Color(0xFF9CA3AF),
      tertiary: const Color(0xFFFCD34D),
      onTertiary: Colors.black,
      tertiaryContainer: const Color(0xFF6366F1),
      onTertiaryContainer: Colors.white,
    );
    return MaterialApp(
      title: 'Kerala Tech Reach',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: lightColorScheme.background,
        cardColor: lightColorScheme.surface,
        dividerColor: lightColorScheme.outline,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: lightColorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: darkColorScheme.background,
        cardColor: darkColorScheme.surface,
        dividerColor: darkColorScheme.outline,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: darkColorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      setState(() {
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _isAuthenticated ? const MainScreen() : const LoginScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    QuestionPapersScreen(),
    EventsScreen(),
    JobListScreen(),
    NotesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Questions',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notes',
          ),
        ],
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
