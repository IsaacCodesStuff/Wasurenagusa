import 'package:flutter/material.dart';
import '../../theme/wasurenagusa_theme.dart';

class NotebooksScreen extends StatelessWidget {
  const NotebooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Notebooks')),
      body: const Center(child: Text('Notebooks')),
    );
  }
}
