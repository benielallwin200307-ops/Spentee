import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('MobileAds initialization error: $e');
  }
  final appState = AppState();
  try {
    await appState.initFromStorage();
  } catch (e) {
    debugPrint('AppState storage init error: $e');
  }
  runApp(SpenteeApp(appState: appState));
}


/// The root widget of Spentee.
class SpenteeApp extends StatefulWidget {
  final AppState? appState;
  const SpenteeApp({super.key, this.appState});

  @override
  State<SpenteeApp> createState() => _SpenteeAppState();
}

class _SpenteeAppState extends State<SpenteeApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.appState ?? AppState();
    if (widget.appState == null) {
      _appState.initFromStorage();
    }
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'Spentee',
            debugShowCheckedModeBanner: false,
            themeMode: _appState.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: _appState.isAuthenticated
                ? const MainShell()
                : const SplashScreen(),
          );
        },
      ),
    );
  }
}

