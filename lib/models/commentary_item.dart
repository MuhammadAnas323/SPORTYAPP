import 'package:equatable/equatable.dart';

/// One commentary entry (ball-by-ball cricket or minute-by-minute football).
class CommentaryItem extends Equatable {
  const CommentaryItem({
    this.id,
    this.over,
    this.minute,
    required this.text,
    this.timestamp,
    this.isHighlight = false,
  });

  final String? id;

  /// Cricket: over number, e.g. "14.3".
  final String? over;

  /// Football: match minute, e.g. "67'".
  final String? minute;

  final String text;
  final DateTime? timestamp;

  /// Provider flags a key event (wicket/goal) — rendered with emphasis.
  final bool isHighlight;

  /// Phase label shown in the gutter.
  String? get phase {
    if (over != null && over!.trim().isNotEmpty) return over;
    if (minute != null && minute!.trim().isNotEmpty) return minute;
    return null;
  }

  @override
  List<Object?> get props => [id, over, minute, text, timestamp, isHighlight];
}
