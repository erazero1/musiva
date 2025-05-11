import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _dombraScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(); // Continuous rotation and animations

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _dombraScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Wait 5 seconds before checking auth status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          context.read<AuthBloc>().add(CheckAuthStatusEvent());
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is Authenticated || state is GuestAuthenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is Unauthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.blue[800],
        body: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/oyular_left.png',
                  height: double.infinity,
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/oyular_right.png',
                  height: double.infinity,
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RotationTransition(
                            turns: _rotationAnimation,
                            child: ScaleTransition(
                              scale: _dombraScale,
                              child: Image.asset(
                                'assets/dombra.png',
                                height: 150,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Musiva',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Your Music, Your Way',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 40),
                          const CircularProgressIndicator(
                            color: Colors.white,
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
      ),
    );
  }
}
