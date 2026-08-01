import 'package:equatable/equatable.dart';

/// A team as returned by any connected API, normalized.
class Team extends Equatable {
  const Team({
    this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
  });

  final String? id;
  final String name;
  final String? shortName;
  final String? logoUrl;

  /// A stable 3-letter style code derived from the name when the API does not
  /// provide one — used for avatars.
  String get code {
    final short = (shortName ?? '').trim();
    if (short.isNotEmpty) return short.toUpperCase();
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      final w = words.first;
      return w.length <= 3 ? w.toUpperCase() : w.substring(0, 3).toUpperCase();
    }
    return words.take(2).map((w) => w[0]).join().toUpperCase();
  }

  @override
  List<Object?> get props => [id, name, shortName, logoUrl];
}
