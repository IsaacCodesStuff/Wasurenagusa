import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_tile.dart';
import 'theme_mode_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';

  // Editor font size — stored as a label for display,
  // actual value handled later when editor is built
  static const List<String> _fontSizeOptions = ['Small', 'Medium', 'Large'];
  String _selectedFontSize = 'Medium';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    ThemeRegistry.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeRegistry.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  void _showFontSizePicker(WasurenagusaColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 16),
                  child: Text(
                    'Editor font size',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: _fontSizeOptions.map((size) {
                      final isFirst = size == _fontSizeOptions.first;
                      final isLast = size == _fontSizeOptions.last;
                      final isSelected = size == _selectedFontSize;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() => _selectedFontSize = size);
                              Navigator.pop(context);
                              // TODO: persist font size preference
                            },
                            borderRadius: BorderRadius.vertical(
                              top: isFirst
                                  ? const Radius.circular(16)
                                  : Radius.zero,
                              bottom: isLast
                                  ? const Radius.circular(16)
                                  : Radius.zero,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    size,
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_rounded,
                                      color: colors.accent,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 20,
                              color: colors.divider,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    final mode = ThemeRegistry.instance.selectedMode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsSection(
            title: 'Appearance',
            children: [
              SettingsTile(
                title: 'Theme mode',
                subtitle: mode.label,
                isFirst: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ThemeModeScreen()),
                ),
              ),
              SettingsTile(
                title: 'Editor font size',
                subtitle: _selectedFontSize,
                isLast: true,
                onTap: () => _showFontSizePicker(colors),
              ),
            ],
          ),
          SettingsSection(
            title: 'About',
            children: [
              SettingsTile(
                title: 'Wasurenagusa',
                subtitle: _version.isEmpty
                    ? 'Loading...'
                    : 'v$_version ($_buildNumber)',
                isFirst: true,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
