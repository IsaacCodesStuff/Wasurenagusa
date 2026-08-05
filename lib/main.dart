import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/wasurenagusa_theme.dart';
import 'app_shell.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await ThemeRegistry.instance.loadFromPrefs(prefs);

  runApp(const ProviderScope(child: WasurenagusaApp()));
}

class WasurenagusaApp extends StatefulWidget {
  const WasurenagusaApp({super.key});

  @override
  State<WasurenagusaApp> createState() => _WasurenagusaAppState();
}

class _WasurenagusaAppState extends State<WasurenagusaApp> {
  late WasurenagusaColorScheme _scheme;

  @override
  void initState() {
    super.initState();
    _scheme = ThemeRegistry.instance.currentScheme;
    ThemeRegistry.instance.addListener(_onThemeChanged);

    final isDark = _scheme.background.computeLuminance() < 0.5;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    ThemeRegistry.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    final scheme = ThemeRegistry.instance.currentScheme;
    final isDark = scheme.background.computeLuminance() < 0.5;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    setState(() {
      _scheme = scheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WasurenagusaTheme(
      colors: _scheme,
      onThemeChange: (scheme) {
        setState(() => _scheme = scheme);
      },
      child: MaterialApp(
        title: 'Wasurenagusa',
        debugShowCheckedModeBanner: false,
        theme: _scheme.toThemeData(),
        home: const AppShell(),
      ),
    );
  }
}
