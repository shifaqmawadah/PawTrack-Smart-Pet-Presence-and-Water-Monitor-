import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://humancc.site/shifaqmawaddah/pawtrack/register.php'),
        body: {
          'username': _username.text,
          'email': _email.text,
          'password': _password.text,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _message = data['message'] ?? 'Registration successful.';
          });

          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        } else {
          setState(() {
            _message = data['message'] ?? 'Registration failed.';
          });
        }
      } else {
        setState(() {
          _message = 'Invalid response from server.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Network error.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBrown = Color(0xFF3A230E);
    const Color reddishBrown = Color(0xFF8B4000);
    const Color goldenOrange = Color(0xFFD2791A);
    const Color cream = Color(0xFFFFE6B3);

    return Scaffold(
      backgroundColor: cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset(
                'assets/images/paw_logo.jpg',
                height: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'PawTrack',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: reddishBrown,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart care for your pet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkBrown,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              if (_message != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              TextFormField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) =>
                    val == null || !val.contains('@') ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) =>
                    val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldenOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _register,
                        child: const Text('Register'),
                      ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: _goToLogin,
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: reddishBrown),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
