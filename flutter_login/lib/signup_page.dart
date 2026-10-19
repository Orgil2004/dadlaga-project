import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'user_data.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final List<String> backgrounds = [
    'assets/images/background1.jpg',
    'assets/images/background2.jpg',
    'assets/images/background3.jpg',
  ];

  int currentImage = 0;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          currentImage = (currentImage + 1) % backgrounds.length;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // Login-той ижил TextField дизайн
  InputDecoration fieldDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white54),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.orangeAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.orangeAccent),
    );
  }

  // Бүртгэл үүсгэх
  void register() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    UserData.name = nameController.text.trim();
    UserData.email = emailController.text.trim();
    UserData.password = passwordController.text;

    // Амжилттай бүртгүүлээд Login руу буцна
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background зураг солигдох
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 2),
              child: Container(
                key: ValueKey(currentImage),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(backgrounds[currentImage]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // 2. Background харанхуй давхарга
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.30)),
          ),

          // 3. Glass Sign Up Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_add_alt_1,
                                size: 54,
                                color: Colors.white,
                              ),

                              const SizedBox(height: 14),

                              const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Sign up to get started',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Full Name
                              TextFormField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: fieldDecoration(
                                  'Full Name',
                                  Icons.person_outline,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Нэрээ оруулна уу';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              // Email
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: fieldDecoration(
                                  'Email',
                                  Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email оруулна уу';
                                  }

                                  final regex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );

                                  if (!regex.hasMatch(value.trim())) {
                                    return 'Email буруу байна';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              // Password
                              TextFormField(
                                controller: passwordController,
                                obscureText: hidePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: fieldDecoration(
                                  'Password',
                                  Icons.lock_outline,
                                  suffix: IconButton(
                                    icon: Icon(
                                      hidePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password оруулна уу';
                                  }

                                  if (value.length < 6) {
                                    return 'Хамгийн багадаа 6 тэмдэгт';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              // Confirm Password
                              TextFormField(
                                controller: confirmController,
                                obscureText: hideConfirmPassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: fieldDecoration(
                                  'Confirm Password',
                                  Icons.lock_reset,
                                  suffix: IconButton(
                                    icon: Icon(
                                      hideConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        hideConfirmPassword =
                                            !hideConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password давтаж оруулна уу';
                                  }

                                  if (value != passwordController.text) {
                                    return 'Password таарахгүй байна';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 28),

                              // Sign Up товч
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.indigo,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'SIGN UP',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Login руу буцах
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Already have an account?',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
