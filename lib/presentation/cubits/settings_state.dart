import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;
  final bool notificationsEnabled;

  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.notificationsEnabled,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      themeMode: ThemeMode.dark,
      locale: Locale('en'),
      notificationsEnabled: true,
    );
  }

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, notificationsEnabled];
}
