import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/notes/home_screen.dart';
import 'features/notebooks/notebooks_screen.dart';
import 'features/notes/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'theme/wasurenagusa_theme.dart';

class ShellIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final shellIndexProvider = NotifierProvider<ShellIndexNotifier, int>(
  ShellIndexNotifier.new,
);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = WasurenagusaTheme.of(context).colors;
    final currentIndex = ref.watch(shellIndexProvider);

    const screens = [
      HomeScreen(),
      NotebooksScreen(),
      SearchScreen(),
      SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (currentIndex != 0) {
          ref.read(shellIndexProvider.notifier).setIndex(0);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: IndexedStack(index: currentIndex, children: screens),
        bottomNavigationBar: currentIndex == 2
            ? null
            : NavigationBar(
                selectedIndex: currentIndex > 2
                    ? currentIndex - 1
                    : currentIndex,
                onDestinationSelected: (index) {
                  final mapped = index >= 2 ? index + 1 : index;
                  ref.read(shellIndexProvider.notifier).setIndex(mapped);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.book_outlined),
                    selectedIcon: Icon(Icons.book_rounded),
                    label: 'Notebooks',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
      ),
    );
  }
}
