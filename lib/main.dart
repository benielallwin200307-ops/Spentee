import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  // Initialize MobileAds asynchronously in background so cold startup is not delayed
  MobileAds.instance.initialize().catchError((e) {
    debugPrint('MobileAds initialization error: $e');
    return InitializationStatus({});
  });

  // Initialize Google Sign-In with Android Credential Manager in the background
  AuthService.instance.init().catchError((e) {
    debugPrint('AuthService init error: $e');
  });

  final appState = AppState();
  try {
    await appState.initFromStorage();
  } catch (e) {
    debugPrint('AppState storage init error: $e');
  }

  // Launch Flutter UI immediately to avoid any black screen or cold-start blocking.
  runApp(SpenteeApp(appState: appState));

  // Initialize notification channels and reschedule saved reminders asynchronously in the background.
  NotificationService.instance.init().then((_) {
    NotificationService.instance.rescheduleAll(
      notifications: appState.notifications,
      notificationTime: appState.notificationTime,
      transactions: appState.transactions,
      budgets: appState.budgets,
      savingsGoals: appState.savingsGoals,
      language: appState.selectedLanguage,
      intensity: appState.roastIntensity,
    );
  }).catchError((e) {
    debugPrint('NotificationService background init error: $e');
  });
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
      child: MaterialApp(
        title: 'Spentee',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: _appState.isAuthenticated
            ? const MainShell()
            : const SplashScreen(),
      ),
    );
  }
}
