extension StringExtensions on String {
  /// Capitalize the first letter.
  String get capitalize =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';

  /// Capitalize every word.
  String get capitalizeWords => split(' ').map((w) => w.capitalize).join(' ');

  /// Truncate to [maxLength] with a trailing [suffix].
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Extract initials (up to 2 characters).
  String get initials {
    final words = trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Check if the string is a valid email.
  bool get isValidEmail => RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(this);

  /// Format as distance string (e.g. "1.2 km" or "450 m").
  String get asDistance {
    final meters = double.tryParse(this);
    if (meters == null) return this;
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }
}
