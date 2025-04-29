import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class UserPreferences extends Equatable {
  final ThemeMode themeMode;
  final String languageCode;

  const UserPreferences({
    this.themeMode = ThemeMode.system,
    this.languageCode = 'en',
  });

  UserPreferences copyWith({
    ThemeMode? themeMode,
    String? languageCode,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'languageCode': languageCode,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      languageCode: json['languageCode'] ?? 'en',
    );
  }

  @override
  List<Object?> get props => [themeMode, languageCode];
}