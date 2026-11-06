/// Dosya boyutunu okunabilir biçime çevirir (ör. 1,4 MB).
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final double kb = bytes / 1024;
  if (kb < 1024) {
    return '${_trim(kb)} KB';
  }
  final double mb = kb / 1024;
  if (mb < 1024) {
    return '${_trim(mb)} MB';
  }
  return '${_trim(mb / 1024)} GB';
}

String _trim(double value) {
  if (value >= 100 || value == value.roundToDouble()) {
    return value.round().toString();
  }
  final String text = value.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}

/// Süreyi mm:ss (gerekirse ss:dd:ss) biçiminde döndürür.
String formatDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  final int hours = minutes ~/ 60;

  String two(int value) => value.toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:${two(minutes % 60)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
}
