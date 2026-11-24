// 5.6 Quán San Hô: where a focus session takes place (spec 006 FR-001, FR-008).

enum StudyPlace {
  /// Gret's own sea (spec 003, spec 005).
  sea,

  /// Quán San Hô, with Gret's sea friends (spec 006).
  cafe;

  /// The place with this stored name, or null for anything else (callers pick the default:
  /// the café for the preference, the sea for sessions saved before the café existed).
  static StudyPlace? tryParse(Object? raw) => raw is String ? values.asNameMap()[raw] : null;
}
