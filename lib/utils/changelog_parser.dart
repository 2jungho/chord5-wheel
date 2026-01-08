import 'package:flutter/services.dart' show rootBundle;
import '../models/changelog_model.dart';

class ChangelogParser {
  static Future<List<ChangelogItem>> loadFromReadme() async {
    try {
      final String content = await rootBundle.loadString('README.md');
      return _parseMarkdown(content);
    } catch (e) {
      // Fallback or error handling
      print('Error loading README.md: $e');
      return [];
    }
  }

  static List<ChangelogItem> _parseMarkdown(String content) {
    final List<ChangelogItem> items = [];
    // Normalize newlines and split
    final List<String> lines = content.replaceAll('\r\n', '\n').split('\n');

    String? currentVersion;
    List<String> currentChanges = [];

    // Flexible version regex: matches "### v1.1.3" or "### v1.1.3 (2024...)"
    final versionRegex = RegExp(r'###\s*(v\d+\.\d+\.\d+)');
    final bulletRegex = RegExp(r'^[\*\-\+]\s+(.*)$');
    final categoryRegex = RegExp(r'^####\s+(.*)$');

    for (String line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 1. Version Header Detection
      final versionMatch = versionRegex.firstMatch(trimmed);
      if (versionMatch != null) {
        if (currentVersion != null && currentChanges.isNotEmpty) {
          items.add(ChangelogItem(
            version: currentVersion,
            changes: List.from(currentChanges),
          ));
        }
        currentVersion = versionMatch.group(1);
        currentChanges = [];
        continue;
      }

      // 2. Collecting changes for current version
      if (currentVersion != null) {
        // Stop if we hit a main header (## ) - end of changelog section
        if (trimmed.startsWith('## ') && !trimmed.startsWith('###')) {
          items.add(ChangelogItem(
            version: currentVersion,
            changes: List.from(currentChanges),
          ));
          currentVersion = null;
          currentChanges = [];
          continue;
        }

        // Category Header (#### )
        final catMatch = categoryRegex.firstMatch(trimmed);
        if (catMatch != null) {
          String category = catMatch.group(1)!.replaceAll('**', '').trim();
          if (category.isNotEmpty) {
            currentChanges.add('[$category]');
          }
          continue;
        }

        // Change Item (Bullet points)
        final bulletMatch = bulletRegex.firstMatch(trimmed);
        if (bulletMatch != null) {
          String cleanLine = bulletMatch.group(1)!.replaceAll('**', '').trim();
          if (cleanLine.isNotEmpty) {
            currentChanges.add(cleanLine);
          }
        }
      }
    }

    // Add last version entry
    if (currentVersion != null && currentChanges.isNotEmpty) {
      items.add(ChangelogItem(
        version: currentVersion,
        changes: List.from(currentChanges),
      ));
    }

    return items;
  }
}
