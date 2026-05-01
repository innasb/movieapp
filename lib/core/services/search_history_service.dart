import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  final SharedPreferences _prefs;
  static const String _key = 'search_history';

  SearchHistoryService(this._prefs);

  List<String> getHistory() {
    return _prefs.getStringList(_key) ?? [];
  }

  Future<void> addQuery(String query) async {
    final history = getHistory();
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) {
      history.removeLast();
    }
    await _prefs.setStringList(_key, history);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_key);
  }

  Future<void> removeQuery(String query) async {
    final history = getHistory();
    history.remove(query);
    await _prefs.setStringList(_key, history);
  }
}
