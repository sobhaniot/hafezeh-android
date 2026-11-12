enum ReviewRating { again, hard, good, easy }

class VocabWord {
  const VocabWord({
    required this.id,
    required this.term,
    required this.meaning,
    required this.nextReview,
    this.example = '',
    this.intervalDays = 0,
    this.repetitions = 0,
  });

  final String id;
  final String term;
  final String meaning;
  final String example;
  final DateTime nextReview;
  final double intervalDays;
  final int repetitions;

  bool get isDue => !nextReview.isAfter(DateTime.now());

  VocabWord withReview(ReviewRating rating) {
    final now = DateTime.now();
    final double nextInterval = switch (rating) {
      ReviewRating.again => 10 / (24 * 60),
      ReviewRating.hard => intervalDays < 1 ? 1.0 : intervalDays * 1.2,
      ReviewRating.good => intervalDays < 1 ? 2.0 : intervalDays * 2,
      ReviewRating.easy => intervalDays < 3 ? 4.0 : intervalDays * 3,
    };
    final due = rating == ReviewRating.again
        ? now.add(const Duration(minutes: 10))
        : now.add(Duration(minutes: (nextInterval * 24 * 60).round()));

    return VocabWord(
      id: id,
      term: term,
      meaning: meaning,
      example: example,
      nextReview: due,
      intervalDays: nextInterval,
      repetitions: rating == ReviewRating.again ? 0 : repetitions + 1,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'term': term,
    'meaning': meaning,
    'example': example,
    'nextReview': nextReview.toIso8601String(),
    'intervalDays': intervalDays,
    'repetitions': repetitions,
  };

  factory VocabWord.fromJson(Map<String, dynamic> json) => VocabWord(
    id: json['id'] as String,
    term: json['term'] as String,
    meaning: json['meaning'] as String,
    example: (json['example'] as String?) ?? '',
    nextReview: DateTime.parse(json['nextReview'] as String),
    intervalDays: (json['intervalDays'] as num?)?.toDouble() ?? 0,
    repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
  );
}

String faNum(Object value) => value
    .toString()
    .replaceAll('0', '۰')
    .replaceAll('1', '۱')
    .replaceAll('2', '۲')
    .replaceAll('3', '۳')
    .replaceAll('4', '۴')
    .replaceAll('5', '۵')
    .replaceAll('6', '۶')
    .replaceAll('7', '۷')
    .replaceAll('8', '۸')
    .replaceAll('9', '۹');
