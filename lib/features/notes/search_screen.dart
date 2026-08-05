import 'package:flutter/material.dart';
import '../../theme/wasurenagusa_theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Search')),
      body: const Center(child: Text('Search')),
    );
  }
}
