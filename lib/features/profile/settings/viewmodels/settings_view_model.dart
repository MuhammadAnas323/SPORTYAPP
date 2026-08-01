import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runtime theme preference (light / dark / system), persisted locally.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _key = 'sportyapp.settings.themeMode';

  @override
  ThemeMode build() {
    // Start with system; the persisted choice is applied as soon as prefs
    // finish loading so there is no blocking I/O during app boot.
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final next = _fromKey(prefs.getString(_key));
    if (state != next) {
      // Defer so the write never happens synchronously inside build() (a
      // cached SharedPreferences resolves its future synchronously).
      scheduleMicrotask(() => state = next);
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  static ThemeMode _fromKey(String? key) => switch (key) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

/// Local notification preference flags (placeholder for a future FCM hook).
final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationPrefs>(
  NotificationsNotifier.new,
);

class NotificationPrefs {
  const NotificationPrefs({
    this.liveStarts = true,
    this.sounds = true,
  });

  final bool liveStarts;
  final bool sounds;

  NotificationPrefs copyWith({bool? liveStarts, bool? sounds}) =>
      NotificationPrefs(
        liveStarts: liveStarts ?? this.liveStarts,
        sounds: sounds ?? this.sounds,
      );
}

class NotificationsNotifier extends Notifier<NotificationPrefs> {
  static const String _key = 'sportyapp.settings.notifications';

  @override
  NotificationPrefs build() {
    _restore();
    return const NotificationPrefs();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final parts = raw.split('|');
    if (parts.length == 2) {
      final next = NotificationPrefs(
        liveStarts: parts[0] == '1',
        sounds: parts[1] == '1',
      );
      // Defer so the write never happens synchronously inside build() (a
      // cached SharedPreferences resolves its future synchronously).
      scheduleMicrotask(() {
        if (state != next) state = next;
      });
    }
  }

  Future<void> setLiveStarts(bool value) => _save(state.copyWith(liveStarts: value));

  Future<void> setSounds(bool value) => _save(state.copyWith(sounds: value));

  Future<void> _save(NotificationPrefs prefs) async {
    state = prefs;
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _key,
      '${prefs.liveStarts ? '1' : '0'}|${prefs.sounds ? '1' : '0'}',
    );
  }
}
