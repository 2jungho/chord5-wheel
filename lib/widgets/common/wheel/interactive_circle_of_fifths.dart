import 'package:flutter/material.dart';
import '../../../models/music_constants.dart';
import 'circle_of_fifths_painter.dart';
import 'circle_of_fifths_math_helper.dart';

class InteractiveCircleOfFifths extends StatelessWidget {
  final double size;
  final String rootNote;
  final String modeName;
  final int currentKeyIndex;
  final bool isInnerRingSelected;
  final Function(int index, bool isInner) onKeySelected;
  final Function(int index, bool isInner)? onKeyLongPressed;

  const InteractiveCircleOfFifths({
    super.key,
    this.size = 320,
    required this.rootNote,
    required this.modeName,
    required this.currentKeyIndex,
    required this.isInnerRingSelected,
    required this.onKeySelected,
    this.onKeyLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    final displayMode = modeName == 'Ionian'
        ? 'MAJOR'
        : (modeName == 'Aeolian' ? 'MINOR' : modeName.toUpperCase());

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _handleWheelTap(details.localPosition),
            onLongPressStart: (details) =>
                _handleWheelLongPress(details.localPosition),
            child: CustomPaint(
              size: Size(size, size),
              painter: CircleOfFifthsPainter(
                selectedKeyIndex: currentKeyIndex,
                isInnerSelected: isInnerRingSelected,
                keys: MusicConstants.KEYS,
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
                  rootNote,
                  style: TextStyle(
                    fontSize: size * 0.15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.0,
                  ),
                ),
                Text(
                  displayMode,
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

  void _handleWheelTap(Offset localPosition) {
    final result = WheelMathHelper.calculateKeySelection(localPosition, size);
    if (result != null) {
      onKeySelected(result.index, result.isInner);
    }
  }

  void _handleWheelLongPress(Offset localPosition) {
    if (onKeyLongPressed == null) return;
    final result = WheelMathHelper.calculateKeySelection(localPosition, size);
    if (result != null) {
      onKeyLongPressed!(result.index, result.isInner);
    }
  }
}
