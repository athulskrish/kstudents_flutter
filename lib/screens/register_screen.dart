import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import '../utils/app_exception.dart';
import '../utils/logger.dart';
import 'email_verification_pending_screen.dart';
import '../services/api_service.dart';
import '../models/district.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  final _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  List<District> _districts = [];
  District? _selectedDistrict;
  bool _isLoadingDistricts = false;

  @override
  void initState() {
    super.initState();
    _fetchDistricts();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchDistricts() async {
    setState(() {
      _isLoadingDistricts = true;
    });
    try {
      final fetchedDistricts = await _apiService.getDistricts();
      setState(() {
        _districts = fetchedDistricts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      AppLogger.error('Error fetching districts', e);
      setState(() {
        _errorMessage = 'Failed to load districts.';
        _isLoadingDistricts = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDistrict == null && _districts.isNotEmpty) {
      setState(() {
        _errorMessage = 'Please select a district.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.info('User registration attempt: ${_usernameController.text}');
      await _authService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        district: _selectedDistrict?.id,
      );
      AppLogger.info('User registration success: ${_usernameController.text}');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => EmailVerificationPendingScreen(email: _emailController.text)),
        );
      }
    } on AppException catch (e) {
      AppLogger.error('User registration failed: ${_usernameController.text}', e);
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      AppLogger.error('Unexpected error during registration: ${_usernameController.text}', e);
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: _isLoadingDistricts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16.0),
                    DropdownButtonFormField<District>(
                decoration: const InputDecoration(
                        labelText: 'District (optional)',
                  border: OutlineInputBorder(),
                ),
                      value: _selectedDistrict,
                      items: _districts.map((district) {
                        return DropdownMenuItem<District>(
                          value: district,
                          child: Text(district.name),
                        );
                      }).toList(),
                      onChanged: (District? newValue) {
                        setState(() {
                          _selectedDistrict = newValue;
                        });
                },
              ),
              const SizedBox(height: 24.0),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ElevatedButton(
                      onPressed: _isLoading || _isLoadingDistricts ? null : _register,
                      child: _isLoading || _isLoadingDistricts
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Register'),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 