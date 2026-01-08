import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/music_constants.dart';
import '../../../views/explorer/circle_of_fifths_wheel.dart';

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
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.0,
                  ),
                ),
                Text(
                  displayMode,
                  style: TextStyle(
                    fontSize: 14,
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
    final result = _calculateSelection(localPosition);
    if (result != null) {
      onKeySelected(result.index, result.isInner);
    }
  }

  void _handleWheelLongPress(Offset localPosition) {
    if (onKeyLongPressed == null) return;
    final result = _calculateSelection(localPosition);
    if (result != null) {
      onKeyLongPressed!(result.index, result.isInner);
    }
  }

  ({int index, bool isInner})? _calculateSelection(Offset localPosition) {
    final center = size / 2;
    final dx = localPosition.dx - center;
    final dy = localPosition.dy - center;
    final dist = sqrt(dx * dx + dy * dy);
    final angle = atan2(dy, dx); // -pi to pi

    // Radii (match Painter)
    final rOuter = size * 0.45;
    final rMiddle = size * 0.32;
    final rInner = size * 0.15;

    if (dist < rInner || dist > rOuter) return null; // Clicked hole or outside

    bool isInner = false;
    if (dist <= rMiddle) {
      isInner = true;
    } else {
      isInner = false;
    }

    double deg = angle * 180 / pi;
    double normalized = deg + 90;
    if (normalized < 0) normalized += 360;

    int index = (normalized / 30).floor() % 12;

    return (index: index, isInner: isInner);
  }
}
