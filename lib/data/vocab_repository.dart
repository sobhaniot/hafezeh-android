import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/vocab_word.dart';

/// Stores the vocabulary JSON in Android's private app preferences.
/// No account or network connection is needed; Android keeps it across restarts.
class VocabRepository {
  static const _channel = MethodChannel('com.hafezeh.app/vocabulary');

  Future<List<VocabWord>> load() async {
    final raw = await _channel.invokeMethod<String>('load');
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => VocabWord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<VocabWord> words) async {
    final raw = jsonEncode(words.map((word) => word.toJson()).toList());
    await _channel.invokeMethod<void>('save', {'data': raw});
  }
}
