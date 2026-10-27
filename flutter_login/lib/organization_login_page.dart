
import 'package:flutter/material.dart';

class OrganizationLoginPage extends StatefulWidget {
  const OrganizationLoginPage({super.key});

  @override
  State<OrganizationLoginPage> createState() =>
      _OrganizationLoginPageState();
}

class _OrganizationLoginPageState
    extends State<OrganizationLoginPage> {

  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void login() {
    if (_formKey.currentState!.validate()) {
      showMessage(
        'Байгууллагын Login одоогоор Backend-тэй холбогдоогүй байна.',
      );
    }
  }

  InputDecoration inputDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: Colors.indigo,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F7FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFDDE3EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.indigo,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07162F),

      body: Stack(
        children: [

          // BACKGROUND GRADIENT
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF07162F),
                    Color(0xFF174477),
                    Color(0xFF090F24),
                  ],
                ),
              ),
            ),
          ),

          // ХААНА ВЭ? 3D БИЧИГ
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Stack(
                    children: [

                      // СҮҮДЭР
                      Transform.translate(
                        offset: const Offset(9, 11),
                        child: const Text(
                          'Хаана Вэ?',
                          style: TextStyle(
                            fontSize: 110,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Color(0xFF020817),
                          ),
                        ),
                      ),

                      // 3D ДУНД ДАВХАРГА
                      Transform.translate(
                        offset: const Offset(4, 5),
                        child: const Text(
                          'Хаана Вэ?',
                          style: TextStyle(
                            fontSize: 110,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Color(0xFF2675BC),
                          ),
                        ),
                      ),

                      // ҮНДСЭН БИЧИГ
                      const Text(
                        'Хаана Вэ?',
                        style: TextStyle(
                          fontSize: 110,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Color(0xFFD9EEFF),
                          shadows: [
                            Shadow(
                              color: Colors.lightBlueAccent,
                              blurRadius: 35,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // LOGIN FORM
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),

                  child: Container(
                    padding: const EdgeInsets.all(28),

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.90,
                      ),

                      borderRadius: BorderRadius.circular(25),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 30,
                        ),
                      ],
                    ),

                    child: Form(
                      key: _formKey,

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [

                          // БАЙГУУЛЛАГЫН ICON
                          const Icon(
                            Icons.business_rounded,
                            size: 55,
                            color: Colors.indigo,
                          ),

                          const SizedBox(height: 20),

                          // TITLE
                          const Text(
                            'Байгууллагын нэвтрэх',
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Хаана Вэ? платформд тавтай морил!',
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // EMAIL
                          TextFormField(
                            controller: emailController,

                            keyboardType:
                                TextInputType.emailAddress,

                            decoration: inputDecoration(
                              'Байгууллагын имэйл',
                              Icons.email_outlined,
                            ),

                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Имэйлээ оруулна уу';
                              }

                              final regex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );

                              if (!regex.hasMatch(
                                value.trim(),
                              )) {
                                return 'Имэйл буруу байна';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // PASSWORD
                          TextFormField(
                            controller: passwordController,

                            obscureText: hidePassword,

                            decoration: inputDecoration(
                              'Нууц үг',
                              Icons.lock_outline,

                              suffix: IconButton(
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.indigo,
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
                                return 'Нууц үгээ оруулна уу';
                              }

                              if (value.length < 6) {
                                return 'Хамгийн багадаа 6 тэмдэгт';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          Align(
                            alignment: Alignment.centerRight,

                            child: TextButton(
                              onPressed: () {
                                showMessage(
                                  'Нууц үг сэргээх үйлдэл '
                                  'одоогоор холбогдоогүй.',
                                );
                              },

                              child: const Text(
                                'Нууц үг мартсан уу?',
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 52,

                            child: ElevatedButton.icon(
                              onPressed: login,

                              icon: const Icon(
                                Icons.login,
                              ),

                              label: const Text(
                                'БАЙГУУЛЛАГААР НЭВТРЭХ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,

                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          const Divider(),

                          const SizedBox(height: 15),

                          const Text(
                            'Танай байгууллага бүртгэлгүй юу?',
                          ),

                          const SizedBox(height: 10),

                          // REGISTER BUTTON
                          OutlinedButton.icon(
                            onPressed: () {
                              showMessage(
                                'Байгууллага бүртгүүлэх хуудас '
                                'одоогоор холбогдоогүй.',
                              );
                            },

                            icon: const Icon(
                              Icons.add_business,
                            ),

                            label: const Text(
                              'Байгууллага бүртгүүлэх',
                            ),
                          ),

                          const SizedBox(height: 15),

                          // BACK BUTTON
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },

                            icon: const Icon(
                              Icons.arrow_back,
                            ),

                            label: const Text(
                              'Хэрэглэгчийн Login руу буцах',
                            ),
                          ),
                        ],
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
