import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/note_repository.dart';

class SortPreferenceNotifier extends Notifier<Map<int, NoteSortOrder>> {
  static const _prefix = 'sort_order_section_';

  @override
  Map<int, NoteSortOrder> build() => {};

  Future<void> loadAll(SharedPreferences prefs) async {
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    final map = <int, NoteSortOrder>{};
    for (final key in keys) {
      final sectionId = int.tryParse(key.replaceFirst(_prefix, ''));
      final value = prefs.getString(key);
      if (sectionId != null && value != null) {
        map[sectionId] = NoteSortOrder.values.firstWhere(
          (e) => e.name == value,
          orElse: () => NoteSortOrder.lastEdited,
        );
      }
    }
    state = map;
  }

  Future<void> setSortOrder(int sectionId, NoteSortOrder order) async {
    state = {...state, sectionId: order};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$sectionId', order.name);
  }

  NoteSortOrder getSortOrder(int sectionId) {
    return state[sectionId] ?? NoteSortOrder.lastEdited;
  }
}

final sortPreferenceProvider =
    NotifierProvider<SortPreferenceNotifier, Map<int, NoteSortOrder>>(
      SortPreferenceNotifier.new,
    );
