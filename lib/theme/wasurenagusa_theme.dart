import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Mode
// ---------------------------------------------------------------------------
enum WasurenagusaMode { light, dark, amoled }

enum WasurenagusaFontSize {
  small,
  medium,
  large;

  String get label => switch (this) {
    WasurenagusaFontSize.small => 'Small',
    WasurenagusaFontSize.medium => 'Medium',
    WasurenagusaFontSize.large => 'Large',
  };

  double get textSize => switch (this) {
    WasurenagusaFontSize.small => 13.0,
    WasurenagusaFontSize.medium => 15.0,
    WasurenagusaFontSize.large => 17.0,
  };

  double get headingSize => switch (this) {
    WasurenagusaFontSize.small => 18.0,
    WasurenagusaFontSize.medium => 22.0,
    WasurenagusaFontSize.large => 26.0,
  };
}

extension WasurenagusaModeLabel on WasurenagusaMode {
  String get label {
    switch (this) {
      case WasurenagusaMode.light:
        return 'Light';
      case WasurenagusaMode.dark:
        return 'Dark';
      case WasurenagusaMode.amoled:
        return 'AMOLED';
    }
  }

  String get description {
    switch (this) {
      case WasurenagusaMode.light:
        return 'Soft paper-like light theme';
      case WasurenagusaMode.dark:
        return 'Deep dark theme, easy on the eyes';
      case WasurenagusaMode.amoled:
        return 'Pure black, saves battery on OLED screens';
    }
  }
}

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------
enum WasurenagusaPalette {
  default_,
  natsuyume,
  rem,
  hestia,
  misaki,
  akane,
  syalis,
  liscia,
  itsuki,
  misumi,
  berryblossom,
  jeanne,
  yoshino,
  erna,
  beta,
}

extension WasurenagusaPaletteLabel on WasurenagusaPalette {
  String get label {
    switch (this) {
      case WasurenagusaPalette.default_:
        return 'Default';
      case WasurenagusaPalette.natsuyume:
        return 'Natsuyume';
      case WasurenagusaPalette.rem:
        return 'Rem';
      case WasurenagusaPalette.hestia:
        return 'Hestia';
      case WasurenagusaPalette.misaki:
        return 'Misaki';
      case WasurenagusaPalette.akane:
        return 'Akane';
      case WasurenagusaPalette.syalis:
        return 'Syalis';
      case WasurenagusaPalette.liscia:
        return 'Liscia';
      case WasurenagusaPalette.itsuki:
        return 'Itsuki';
      case WasurenagusaPalette.misumi:
        return 'Misumi';
      case WasurenagusaPalette.berryblossom:
        return 'Berry Blossom';
      case WasurenagusaPalette.jeanne:
        return 'Jeanne';
      case WasurenagusaPalette.yoshino:
        return 'Yoshino';
      case WasurenagusaPalette.erna:
        return 'Erna';
      case WasurenagusaPalette.beta:
        return 'Beta';
    }
  }
}

// ---------------------------------------------------------------------------
// Color scheme
// ---------------------------------------------------------------------------
class WasurenagusaColorScheme {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color primaryVariant;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color accent;
  final Color divider;

  const WasurenagusaColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.primaryVariant,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.accent,
    required this.divider,
  });

  WasurenagusaColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? primary,
    Color? primaryVariant,
    Color? onBackground,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? accent,
    Color? divider,
  }) => WasurenagusaColorScheme(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    primary: primary ?? this.primary,
    primaryVariant: primaryVariant ?? this.primaryVariant,
    onBackground: onBackground ?? this.onBackground,
    onSurface: onSurface ?? this.onSurface,
    onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
    accent: accent ?? this.accent,
    divider: divider ?? this.divider,
  );

  // -------------------------------------------------------------------------
  // Base schemes
  // -------------------------------------------------------------------------
  static const dark = WasurenagusaColorScheme(
    background: Color(0xFF0F1018),
    surface: Color(0xFF181922),
    surfaceVariant: Color(0xFF22242F),
    primary: Color(0xFFCCDFFB),
    primaryVariant: Color(0xFFF6E8DC),
    onBackground: Color(0xFFEBEFFB),
    onSurface: Color(0xFFCDD8F0),
    onSurfaceVariant: Color(0xFF8896B8),
    accent: Color(0xFF90BFF9),
    divider: Color(0xFF2A2C3A),
  );

  static const light = WasurenagusaColorScheme(
    background: Color(0xFFF2F6FE),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFDEEAFD),
    primary: Color(0xFF1A4A8C),
    primaryVariant: Color(0xFF2E62B0),
    onBackground: Color(0xFF0E1830),
    onSurface: Color(0xFF1A2540),
    onSurfaceVariant: Color(0xFF4A5E80),
    accent: Color(0xFF3A7FD4),
    divider: Color(0xFFBDD0F0),
  );

  static const amoled = WasurenagusaColorScheme(
    background: Color(0xFF000000),
    surface: Color(0xFF080A12),
    surfaceVariant: Color(0xFF10131E),
    primary: Color(0xFFCCDFFB),
    primaryVariant: Color(0xFFF6E8DC),
    onBackground: Color(0xFFEBEFFB),
    onSurface: Color(0xFFCDD8F0),
    onSurfaceVariant: Color(0xFF8896B8),
    accent: Color(0xFF90BFF9),
    divider: Color(0xFF141620),
  );

  // -------------------------------------------------------------------------
  // Palette accents — ported directly from Aozora
  // -------------------------------------------------------------------------
  static ({Color accent, Color primary, Color primaryVariant}) _paletteAccents(
    WasurenagusaPalette palette,
    bool isDark,
  ) {
    switch (palette) {
      case WasurenagusaPalette.default_:
        return (
          accent: const Color(0xFF9A7BFF),
          primary: const Color(0xFFDCCBFF),
          primaryVariant: const Color(0xFFBBAEDD),
        );
      case WasurenagusaPalette.natsuyume:
        return isDark
            ? (
                accent: const Color(0xFF90BFF9),
                primary: const Color(0xFFCCDFFB),
                primaryVariant: const Color(0xFFF6E8DC),
              )
            : (
                accent: const Color(0xFF3A7FD4),
                primary: const Color(0xFF1A4A8C),
                primaryVariant: const Color(0xFF8C5A3C),
              );
      case WasurenagusaPalette.rem:
        return isDark
            ? (
                accent: const Color(0xFF6FA8FF),
                primary: const Color(0xFFD7E4FF),
                primaryVariant: const Color(0xFFA7B3D6),
              )
            : (
                accent: const Color(0xFF3B7DDD),
                primary: const Color(0xFF1A4A8A),
                primaryVariant: const Color(0xFF2D5FAA),
              );
      case WasurenagusaPalette.hestia:
        return isDark
            ? (
                accent: const Color(0xFF7DE7FF),
                primary: const Color(0xFFEDE6D4),
                primaryVariant: const Color(0xFFB8D6E6),
              )
            : (
                accent: const Color(0xFF00A7D8),
                primary: const Color(0xFF2A3448),
                primaryVariant: const Color(0xFF5B718E),
              );
      case WasurenagusaPalette.misaki:
        return isDark
            ? (
                accent: const Color(0xFFB8A0FF),
                primary: const Color(0xFFE0D8FF),
                primaryVariant: const Color(0xFFC4B8F0),
              )
            : (
                accent: const Color(0xFF7B5FD4),
                primary: const Color(0xFF3A2880),
                primaryVariant: const Color(0xFF5A42A8),
              );
      case WasurenagusaPalette.akane:
        return isDark
            ? (
                accent: const Color(0xFFFF8FA0),
                primary: const Color(0xFFFFD8DE),
                primaryVariant: const Color(0xFFE8B0B8),
              )
            : (
                accent: const Color(0xFFD43050),
                primary: const Color(0xFF801828),
                primaryVariant: const Color(0xFFA82840),
              );
      case WasurenagusaPalette.syalis:
        return isDark
            ? (
                accent: const Color(0xFFA8D8B8),
                primary: const Color(0xFFD8F0E0),
                primaryVariant: const Color(0xFFB8D8C4),
              )
            : (
                accent: const Color(0xFF3A8A58),
                primary: const Color(0xFF1A4A30),
                primaryVariant: const Color(0xFF2A6844),
              );
      case WasurenagusaPalette.liscia:
        return isDark
            ? (
                accent: const Color(0xFFFFD080),
                primary: const Color(0xFFFFF0C8),
                primaryVariant: const Color(0xFFE8D0A0),
              )
            : (
                accent: const Color(0xFFB88020),
                primary: const Color(0xFF604010),
                primaryVariant: const Color(0xFF906020),
              );
      case WasurenagusaPalette.itsuki:
        return isDark
            ? (
                accent: const Color(0xFF80D8FF),
                primary: const Color(0xFFC8F0FF),
                primaryVariant: const Color(0xFFA0D8F0),
              )
            : (
                accent: const Color(0xFF0080B8),
                primary: const Color(0xFF004060),
                primaryVariant: const Color(0xFF006090),
              );
      case WasurenagusaPalette.misumi:
        return isDark
            ? (
                accent: const Color(0xFFC8A0E8),
                primary: const Color(0xFFE8D8FF),
                primaryVariant: const Color(0xFFD0B8E8),
              )
            : (
                accent: const Color(0xFF8040B8),
                primary: const Color(0xFF402060),
                primaryVariant: const Color(0xFF603090),
              );
      case WasurenagusaPalette.berryblossom:
        return isDark
            ? (
                accent: const Color(0xFFFF90C8),
                primary: const Color(0xFFFFD0E8),
                primaryVariant: const Color(0xFFE8A8D0),
              )
            : (
                accent: const Color(0xFFD03880),
                primary: const Color(0xFF701840),
                primaryVariant: const Color(0xFFA02860),
              );
      case WasurenagusaPalette.jeanne:
        return isDark
            ? (
                accent: const Color(0xFFE8E0B8),
                primary: const Color(0xFFFFF8E0),
                primaryVariant: const Color(0xFFD8D0A8),
              )
            : (
                accent: const Color(0xFF807040),
                primary: const Color(0xFF403808),
                primaryVariant: const Color(0xFF605828),
              );
      case WasurenagusaPalette.yoshino:
        return isDark
            ? (
                accent: const Color(0xFFFFB8C8),
                primary: const Color(0xFFFFE0E8),
                primaryVariant: const Color(0xFFE8C0D0),
              )
            : (
                accent: const Color(0xFFD05878),
                primary: const Color(0xFF703040),
                primaryVariant: const Color(0xFFA04860),
              );
      case WasurenagusaPalette.erna:
        return isDark
            ? (
                accent: const Color(0xFF90E8D8),
                primary: const Color(0xFFC8FFF8),
                primaryVariant: const Color(0xFFA8E0D8),
              )
            : (
                accent: const Color(0xFF208878),
                primary: const Color(0xFF084838),
                primaryVariant: const Color(0xFF186858),
              );
      case WasurenagusaPalette.beta:
        return isDark
            ? (
                accent: const Color(0xFFD0D0D0),
                primary: const Color(0xFFF0F0F0),
                primaryVariant: const Color(0xFFB8B8B8),
              )
            : (
                accent: const Color(0xFF484848),
                primary: const Color(0xFF202020),
                primaryVariant: const Color(0xFF383838),
              );
    }
  }

  // -------------------------------------------------------------------------
  // resolve()
  // -------------------------------------------------------------------------
  static WasurenagusaColorScheme resolve({
    required WasurenagusaMode mode,
    WasurenagusaPalette palette = WasurenagusaPalette.default_,
  }) {
    final WasurenagusaColorScheme base;
    switch (mode) {
      case WasurenagusaMode.light:
        base = light;
        break;
      case WasurenagusaMode.dark:
        base = dark;
        break;
      case WasurenagusaMode.amoled:
        base = amoled;
        break;
    }

    if (palette == WasurenagusaPalette.default_) return base;

    final isDark = mode != WasurenagusaMode.light;
    final accents = _paletteAccents(palette, isDark);
    return WasurenagusaColorScheme(
      background: base.background,
      surface: base.surface,
      surfaceVariant: base.surfaceVariant,
      onBackground: base.onBackground,
      onSurface: base.onSurface,
      onSurfaceVariant: base.onSurfaceVariant,
      divider: base.divider,
      accent: accents.accent,
      primary: accents.primary,
      primaryVariant: accents.primaryVariant,
    );
  }

  // -------------------------------------------------------------------------
  // toThemeData()
  // -------------------------------------------------------------------------
  ThemeData toThemeData() {
    final isDark = background.computeLuminance() < 0.5;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: isDark ? Brightness.dark : Brightness.light,
      surface: surface,
    ).copyWith(surface: surface, onSurface: onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: onSurface),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent, // add this
          systemNavigationBarDividerColor: Colors.transparent, // add this
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark, // add this
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(color: onSurfaceVariant, fontSize: 13),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
        elevation: 0,
        height: 64,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
    );
  }
}

// ---------------------------------------------------------------------------
// InheritedWidget
// ---------------------------------------------------------------------------
class WasurenagusaTheme extends InheritedWidget {
  final WasurenagusaColorScheme colors;
  final void Function(WasurenagusaColorScheme) onThemeChange;

  const WasurenagusaTheme({
    super.key,
    required this.colors,
    required this.onThemeChange,
    required super.child,
  });

  static WasurenagusaTheme of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<WasurenagusaTheme>();
    assert(result != null, 'No WasurenagusaTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(WasurenagusaTheme oldWidget) =>
      colors != oldWidget.colors;
}

// ---------------------------------------------------------------------------
// ThemeProvider — StatefulWidget wrapper (Aozora pattern)
// ---------------------------------------------------------------------------
class WasurenagusaThemeProvider extends StatefulWidget {
  final Widget child;
  const WasurenagusaThemeProvider({super.key, required this.child});

  @override
  State<WasurenagusaThemeProvider> createState() =>
      _WasurenagusaThemeProviderState();
}

// ---------------------------------------------------------------------------
// ThemeRegistry — singleton state manager
// ---------------------------------------------------------------------------
class ThemeRegistry extends ChangeNotifier {
  ThemeRegistry._();
  static final ThemeRegistry instance = ThemeRegistry._();

  WasurenagusaMode _mode = WasurenagusaMode.dark;
  WasurenagusaPalette _palette = WasurenagusaPalette.default_;

  WasurenagusaMode get selectedMode => _mode;
  WasurenagusaPalette get selectedPalette => _palette;

  WasurenagusaColorScheme get currentScheme =>
      WasurenagusaColorScheme.resolve(mode: _mode, palette: _palette);

  WasurenagusaFontSize _fontSize = WasurenagusaFontSize.medium;
  WasurenagusaFontSize get selectedFontSize => _fontSize;

  void selectFontSize(WasurenagusaFontSize size) {
    _fontSize = size;
    _save();
    notifyListeners();
  }

  void selectMode(WasurenagusaMode mode) {
    _mode = mode;
    _save();
    notifyListeners();
  }

  void selectPalette(WasurenagusaPalette palette) {
    _palette = palette;
    _save();
    notifyListeners();
  }

  void reset() {
    _mode = WasurenagusaMode.dark;
    _palette = WasurenagusaPalette.default_;
    _save();
    notifyListeners();
  }

  static const _keyMode = 'theme_mode';
  static const _keyPalette = 'theme_palette';

  Future<void> loadFromPrefs(SharedPreferences prefs) async {
    final modeStr = prefs.getString(_keyMode);
    if (modeStr != null) {
      _mode = WasurenagusaMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => WasurenagusaMode.dark,
      );
    }
    final paletteStr = prefs.getString(_keyPalette);
    if (paletteStr != null) {
      _palette = WasurenagusaPalette.values.firstWhere(
        (p) => p.name == paletteStr,
        orElse: () => WasurenagusaPalette.default_,
      );
    }
    final fontSizeStr = prefs.getString('font_size');
    if (fontSizeStr != null) {
      _fontSize = WasurenagusaFontSize.values.firstWhere(
        (f) => f.name == fontSizeStr,
        orElse: () => WasurenagusaFontSize.medium,
      );
    }
  }

  void _save() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyMode, _mode.name);
      prefs.setString(_keyPalette, _palette.name);
      prefs.setString('font_size', _fontSize.name);
    });
  }
}

class _WasurenagusaThemeProviderState extends State<WasurenagusaThemeProvider> {
  WasurenagusaColorScheme _colors = WasurenagusaColorScheme.resolve(
    mode: WasurenagusaMode.dark,
  );

  @override
  void initState() {
    super.initState();
    // Sync to whatever was loaded from prefs
    _colors = ThemeRegistry.instance.currentScheme;
    ThemeRegistry.instance.addListener(_onRegistryChanged);
  }

  @override
  void dispose() {
    ThemeRegistry.instance.removeListener(_onRegistryChanged);
    super.dispose();
  }

  void _onRegistryChanged() {
    final scheme = ThemeRegistry.instance.currentScheme;
    final isDark = scheme.background.computeLuminance() < 0.5;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    setState(() => _colors = scheme);
  }

  void _updateTheme(WasurenagusaColorScheme newColors) {
    setState(() => _colors = newColors);
  }

  @override
  Widget build(BuildContext context) {
    return WasurenagusaTheme(
      colors: _colors,
      onThemeChange: _updateTheme,
      child: widget.child,
    );
  }
}
