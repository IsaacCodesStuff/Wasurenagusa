import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_tile.dart';
import 'theme_mode_screen.dart';
import 'palette_screen.dart';
import 'export_screen.dart';
import 'import_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    ThemeRegistry.instance.addListener(_onRegistryChanged);
  }

  @override
  void dispose() {
    ThemeRegistry.instance.removeListener(_onRegistryChanged);
    super.dispose();
  }

  void _onRegistryChanged() => setState(() {});

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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: SingleChildScrollView(
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
                    children: WasurenagusaFontSize.values.map((size) {
                      final isFirst = size == WasurenagusaFontSize.values.first;
                      final isLast = size == WasurenagusaFontSize.values.last;
                      final isSelected =
                          ThemeRegistry.instance.selectedFontSize == size;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              ThemeRegistry.instance.selectFontSize(size);
                              Navigator.pop(context);
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
                                  Expanded(
                                    child: Text(
                                      size.label,
                                      style: TextStyle(
                                        color: colors.onSurface,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    final registry = ThemeRegistry.instance;

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
                subtitle: registry.selectedMode.label,
                isFirst: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ThemeModeScreen()),
                ),
              ),
              SettingsTile(
                title: 'Color palette',
                subtitle: registry.selectedPalette.label,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaletteScreen()),
                ),
              ),
              SettingsTile(
                title: 'Editor font size',
                subtitle: registry.selectedFontSize.label,
                isLast: true,
                onTap: () => _showFontSizePicker(colors),
              ),
            ],
          ),
          SettingsSection(
            title: 'Editor',
            children: [
              SettingsTile(
                title: 'Markdown rendering',
                subtitle: 'Format text when block is unfocused',
                isFirst: true,
                isLast: true,
                trailing: Switch(
                  value: registry.markdownEnabled,
                  onChanged: (val) => registry.setMarkdownEnabled(val),
                  activeThumbColor: colors.accent,
                ),
              ),
            ],
          ),
          SettingsSection(
            title: 'Backup & Restore',
            children: [
              SettingsTile(
                title: 'Export notes',
                subtitle: 'Save notes as a ZIP file',
                isFirst: true,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ExportScreen())),
              ),
              SettingsTile(
                title: 'Import notes',
                subtitle: 'Restore notes from a ZIP file',
                isLast: true,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ImportScreen())),
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
