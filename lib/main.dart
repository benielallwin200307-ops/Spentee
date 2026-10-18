import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final appState = AppState();
  await appState.initFromStorage();
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

