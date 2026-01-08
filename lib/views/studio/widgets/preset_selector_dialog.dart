import 'package:flutter/material.dart';
import '../../../models/progression/progression_presets.dart';

class PresetSelectorDialog extends StatefulWidget {
  final Function(String) onSelected;
  final Function(String, String) onApply;

  const PresetSelectorDialog({
    super.key,
    required this.onSelected,
    required this.onApply,
  });

  @override
  State<PresetSelectorDialog> createState() => _PresetSelectorDialogState();
}

class _PresetSelectorDialogState extends State<PresetSelectorDialog> {
  String _searchQuery = '';
  final Set<String> _selectedTags = {};
  late List<String> _allTags;

  @override
  void initState() {
    super.initState();
    // Extract unique tags and sort them
    final tags = <String>{};
    for (final preset in kProgressionPresets) {
      tags.addAll(preset.tags);
    }
    final sortedList = tags.toList()..sort();
    // Prioritize specific tags
    final priority = ['Jazz', 'Blues', 'Pop', 'Basic'];
    for (final p in priority.reversed) {
      if (sortedList.contains(p)) {
        sortedList.remove(p);
        sortedList.insert(0, p);
      }
    }
    _allTags = sortedList;
  }

  List<ProgressionPreset> get _filteredPresets {
    return kProgressionPresets.where((preset) {
      // 1. Tag filter
      if (_selectedTags.isNotEmpty) {
        bool hasTag = false;
        for (final tag in _selectedTags) {
          if (preset.tags.contains(tag)) {
            hasTag = true;
            break;
          }
        }
        if (!hasTag) return false;
      }

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return preset.title.toLowerCase().contains(query) ||
            preset.description.toLowerCase().contains(query) ||
            preset.progression.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '코드 진행 프리셋 선택',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '원하는 스타일이나 장르를 선택하여 빠르게 진행을 입력하세요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '프리셋 이름, 설명, 코드 검색...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Tag Filters
            Text(
              '장르 / 스타일 태그',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _allTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : null,
                      ),
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      selectedColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      checkmarkColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredPresets.length,
                itemBuilder: (context, index) {
                  final preset = _filteredPresets[index];
                  return Card(
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                        .withOpacity(0.5),
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Single click: Fill search bar
                        widget.onSelected(preset.progression);
                      },
                      onDoubleTap: () {
                        // Double click: Apply immediately
                        widget.onApply(preset.progression, preset.title);
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  preset.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    preset.progression,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              preset.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: preset.tags.map((tag) {
                                return Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
