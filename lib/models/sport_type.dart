/// Sports SportSync knows how to render today.
///
/// This enum is the extension point for future sports: adding `basketball`
/// means registering a matching [SportsApiAdapter] (see `services/adapters/`)
/// and adding a chip label. Everything downstream (models, UI, feed
/// aggregation) is already sport-agnostic.
enum SportType {
  cricket,
  football,
  other;

  /// Stable wire value used in persisted connections (rename-safe).
  String get key => name;

  /// Human label shown in chips and forms.
  String get label => switch (this) {
        SportType.cricket => 'Cricket',
        SportType.football => 'Football',
        SportType.other => 'Other',
      };

  static SportType fromKey(String? value) => switch (value) {
        'cricket' => SportType.cricket,
        'football' => SportType.football,
        _ => SportType.other,
      };
}
