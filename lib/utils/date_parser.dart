class DateParser {
  /// Safely parses a timestamp string into a DateTime.
  /// Returns null if the value is null, empty, or unparseable.
  /// Never falls back to DateTime.now() — a security system must not
  /// silently fabricate timestamps.
  static DateTime? safeParse(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    // If the format is like '2026-07-17 12:00:00' missing the 'T',
    // inject the 'T' to make it ISO 8601 compliant.
    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');

    return DateTime.tryParse(normalized);
  }
}
