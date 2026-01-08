class ChangelogItem {
  final String version;
  final String date; // Optional, might not always be parseable
  final List<String> changes;

  const ChangelogItem({
    required this.version,
    this.date = '',
    required this.changes,
  });
}
