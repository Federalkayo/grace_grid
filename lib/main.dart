import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/book_flip_splash_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp notice: $e');
  }

  runApp(
    const ProviderScope(
      child: GraceGridApp(),
    ),
  );
}

class GraceGridApp extends StatelessWidget {
  const GraceGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GraceGrid Sanctuary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const BookFlipSplashScreen(),
    );
  }
}
