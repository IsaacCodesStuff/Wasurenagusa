import 'package:flutter/material.dart';
import '../../theme/wasurenagusa_theme.dart';

class PaletteScreen extends StatefulWidget {
  const PaletteScreen({super.key});

  @override
  State<PaletteScreen> createState() => _PaletteScreenState();
}

class _PaletteScreenState extends State<PaletteScreen> {
  WasurenagusaPalette _selected = ThemeRegistry.instance.selectedPalette;

  void _applyPalette(WasurenagusaPalette palette) {
    setState(() => _selected = palette);
    ThemeRegistry.instance.selectPalette(palette);
    WasurenagusaTheme.of(
      context,
    ).onThemeChange(ThemeRegistry.instance.currentScheme);
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Color palette')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 16, 8),
            child: Text(
              'PALETTE',
              style: TextStyle(
                color: colors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: WasurenagusaPalette.values.map((palette) {
                final isFirst = palette == WasurenagusaPalette.values.first;
                final isLast = palette == WasurenagusaPalette.values.last;
                final isSelected = palette == _selected;

                // Resolve accent color for this palette
                final previewScheme = WasurenagusaColorScheme.resolve(
                  mode: ThemeRegistry.instance.selectedMode,
                  palette: palette,
                );

                return Column(
                  children: [
                    InkWell(
                      onTap: () => _applyPalette(palette),
                      borderRadius: BorderRadius.vertical(
                        top: isFirst ? const Radius.circular(16) : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Accent color preview circle
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: previewScheme.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.divider,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                palette.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? colors.accent
                                      : colors.onSurface,
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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
                        indent: 68,
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
