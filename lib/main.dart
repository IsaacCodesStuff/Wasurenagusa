import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/wasurenagusa_theme.dart';
import 'app_shell.dart';
import 'core/providers/sort_preference_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await ThemeRegistry.instance.loadFromPrefs(prefs);

  runApp(ProviderScope(child: WasurenagusaApp(prefs: prefs)));
}

class WasurenagusaApp extends StatelessWidget {
  final SharedPreferences prefs;
  const WasurenagusaApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return WasurenagusaThemeProvider(
      child: _WasurenagusaMaterialApp(prefs: prefs),
    );
  }
}

class _WasurenagusaMaterialApp extends ConsumerStatefulWidget {
  final SharedPreferences prefs;
  const _WasurenagusaMaterialApp({required this.prefs});

  @override
  ConsumerState<_WasurenagusaMaterialApp> createState() =>
      _WasurenagusaMaterialAppState();
}

class _WasurenagusaMaterialAppState
    extends ConsumerState<_WasurenagusaMaterialApp> {
  @override
  void initState() {
    super.initState();
    // Defer until after first frame to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sortPreferenceProvider.notifier).loadAll(widget.prefs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    return MaterialApp(
      title: 'Wasurenagusa',
      debugShowCheckedModeBanner: false,
      theme: colors.toThemeData(),
      home: const AppShell(),
    );
  }
}
