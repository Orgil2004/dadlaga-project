
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'home_page.dart';
import 'signup_page.dart';
import 'user_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ХаанаВэ?',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final List<String> backgrounds = [
    'assets/images/background1.jpg',
    'assets/images/background2.jpg',
    'assets/images/background3.jpg',
  ];

  int currentImage = 0;
  bool hidePassword = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (mounted) {
          setState(() {
            currentImage =
                (currentImage + 1) % backgrounds.length;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Login шалгах
  void login() {
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (email == UserData.email &&
          password == UserData.password) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      } else {
        showMessage('Email эсвэл Password буруу байна!');
      }
    }
  }

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
        borderSide: const BorderSide(
          color: Colors.white,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.orangeAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.orangeAccent,
          width: 2,
        ),
      ),
      errorStyle: const TextStyle(
        color: Colors.orangeAccent,
      ),
    );
  }

  // Font Awesome social login товч
  Widget socialButton(
    String name,
    FaIconData icon,
    Color color,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          showMessage('$name Login одоогоор холбогдоогүй');
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor:
              Colors.white.withValues(alpha: 0.15),
          side: const BorderSide(color: Colors.white54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: FaIcon(
          icon,
          size: 27,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background зураг солигдох
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 2),
              child: Container(
                key: ValueKey(currentImage),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      backgrounds[currentImage],
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // Background харанхуй давхарга
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.30),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 18,
                        sigmaY: 18,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 54,
                                color: Colors.white,
                              ),

                              const SizedBox(height: 14),

                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Sign in to continue',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Email
                              TextFormField(
                                controller: emailController,
                                keyboardType:
                                    TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                                decoration: fieldDecoration(
                                  'Email',
                                  Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Email оруулна уу';
                                  }

                                  final regex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );

                                  if (!regex.hasMatch(
                                    value.trim(),
                                  )) {
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
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
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
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Password оруулна уу';
                                  }

                                  if (value.length < 6) {
                                    return 'Хамгийн багадаа 6 тэмдэгт';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 5),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    showMessage(
                                      'Forgot Password одоогоор хийгдээгүй',
                                    );
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Login товч
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.indigo,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              const Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'OR CONTINUE WITH',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Social Login
                              Row(
                                children: [
                                  socialButton(
                                    'Google',
                                    FontAwesomeIcons.google,
                                    Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  socialButton(
                                    'Facebook',
                                    FontAwesomeIcons.facebook,
                                    const Color(0xFF1877F2),
                                  ),
                                  const SizedBox(width: 12),
                                  socialButton(
                                    'Apple',
                                    FontAwesomeIcons.apple,
                                    Colors.white,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Sign Up
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SignUpPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Sign Up',
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
