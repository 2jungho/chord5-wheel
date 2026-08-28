import 'package:flutter/material.dart';
import '../../models/music_constants.dart';
import 'wheel/circle_of_fifths_painter.dart';
import 'wheel/circle_of_fifths_math_helper.dart';

class CircleOfFifthsSelector extends StatelessWidget {
  final String currentKey;
  final Function(String) onKeySelected;
  final double size;

  const CircleOfFifthsSelector({
    super.key,
    required this.currentKey,
    required this.onKeySelected,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    final parts = currentKey.split(' ');
    final root = parts[0];
    final mode = parts.length > 1 ? parts[1] : 'Major';
    final isMinor = mode == 'Minor';

    final keys = MusicConstants.KEYS;
    int selectedIndex = 0;

    for (int i = 0; i < keys.length; i++) {
      if (isMinor) {
        if (keys[i].minor == root || keys[i].minor.replaceAll('m', '') == root) {
          selectedIndex = i;
          break;
        }
      } else {
        if (keys[i].name == root) {
          selectedIndex = i;
          break;
        }
      }
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final result =
                  WheelMathHelper.calculateKeySelection(details.localPosition, size);
              if (result != null) {
                final keyData = keys[result.index];
                final scaleName = result.isInner ? keyData.minor : keyData.name;
                final modeName = result.isInner ? 'Minor' : 'Major';
                onKeySelected('$scaleName $modeName');
              }
            },
            child: CustomPaint(
              size: Size(size, size),
              painter: CircleOfFifthsPainter(
                selectedKeyIndex: selectedIndex,
                isInnerSelected: isMinor,
                keys: keys,
                theme: Theme.of(context),
              ),
            ),
          ),
          // Center Text
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  root,
                  style: TextStyle(
                    fontSize: size * 0.15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.0,
                  ),
                ),
                Text(
                  mode.toUpperCase(),
                  style: TextStyle(
                    fontSize: size * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
