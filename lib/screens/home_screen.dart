import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanguiemos_frontend/core/providers/logged_user_provider.dart';
import 'package:hanguiemos_frontend/screens/events_screen.dart';
import 'package:hanguiemos_frontend/screens/login_screen.dart';
import 'package:hanguiemos_frontend/services/local_auth_service.dart';
import 'package:hanguiemos_frontend/services/local_storage.dart';
import 'package:hanguiemos_frontend/services/logged_user_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const String name = 'home-screen';
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final loggedUserService = LoggedUserService();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = LocalStorage.prefs.getString("token");
      if (token == null) {
        if (mounted) context.goNamed(LoginScreen.name);
      } else {
        final isAuthenticated = await LocalAuth.authenticate();
        if (isAuthenticated) {
          final loggedUser = await loggedUserService.fetchUserByToken(token);
          if (mounted) {
            ref.read(loggedUserProvider.notifier).updateLoggedUser(loggedUser);
            context.goNamed(EventsScreen.name);
          }
        }
      }
    });
  }

  Future<void> _authenticate(BuildContext context) async {
    final isAuthenticated = await LocalAuth.authenticate();
    if (isAuthenticated) {
      final token = LocalStorage.prefs.getString("token");
      final loggedUserService = LoggedUserService();
      final loggedUser = await loggedUserService.fetchUserByToken(token!);
      if (mounted) {
        ref.read(loggedUserProvider.notifier).updateLoggedUser(loggedUser);
        context.goNamed(EventsScreen.name);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Autenticación fallida. Por favor, intente nuevamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurpleAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hanguiemos',
                style: TextStyle(
                  fontSize: 48.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              kIsWeb
                  ? const SizedBox.shrink()
                  : ElevatedButton.icon(
                      onPressed: () => _authenticate(context),
                      icon: Platform.isIOS
                          ? const Icon(Icons.face, size: 32)
                          : const Icon(Icons.fingerprint, size: 32),
                      label: Platform.isIOS
                          ? const Text('Autenticarse con Face ID')
                          : const Text('Autenticarse con huella digital'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
