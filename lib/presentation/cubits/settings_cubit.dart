import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _prefs;

  SettingsCubit(this._prefs) : super(SettingsState.initial()) {
    _loadSettings();
  }

  void _loadSettings() {
    final isDarkMode = _prefs.getBool('isDarkMode') ?? true;
    final languageCode = _prefs.getString('languageCode') ?? 'en';
    final notifications = _prefs.getBool('notificationsEnabled') ?? true;

    emit(
      state.copyWith(
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        locale: Locale(languageCode),
        notificationsEnabled: notifications,
      ),
    );
  }

  Future<void> updateThemeMode(bool isDark) async {
    await _prefs.setBool('isDarkMode', isDark);
    emit(state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light));
  }

  Future<void> updateLocale(Locale locale) async {
    await _prefs.setString('languageCode', locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  Future<void> updateNotifications(bool enabled) async {
    await _prefs.setBool('notificationsEnabled', enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
  }
}
