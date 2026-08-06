import 'package:flutter/material.dart';
import '../../theme/wasurenagusa_theme.dart';

class ThemeModeScreen extends StatefulWidget {
  const ThemeModeScreen({super.key});

  @override
  State<ThemeModeScreen> createState() => _ThemeModeScreenState();
}

class _ThemeModeScreenState extends State<ThemeModeScreen> {
  WasurenagusaMode _selected = ThemeRegistry.instance.selectedMode;

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Theme mode')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: WasurenagusaMode.values.map((mode) {
                final isFirst = mode == WasurenagusaMode.values.first;
                final isLast = mode == WasurenagusaMode.values.last;
                final isSelected = mode == _selected;

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _selected = mode);
                        ThemeRegistry.instance.selectMode(mode);
                        WasurenagusaTheme.of(
                          context,
                        ).onThemeChange(ThemeRegistry.instance.currentScheme);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.vertical(
                        top: isFirst ? const Radius.circular(16) : Radius.zero,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.label,
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mode.description,
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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
    );
  }
}
