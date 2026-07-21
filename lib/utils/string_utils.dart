String generateDynamicFileName() {
  final now = DateTime.now();

  final yy = now.year
      .toString()
      .substring(2)
      .padLeft(2, '0'); // ultimi 2 cifre anno
  final mm = now.month.toString().padLeft(2, '0');
  final dd = now.day.toString().padLeft(2, '0');
  final hh = now.hour.toString().padLeft(2, '0');
  final mi = now.minute.toString().padLeft(2, '0');
  final ss = now.second.toString().padLeft(2, '0');

  return '$yy$mm$dd$hh$mi$ss.json';
}
