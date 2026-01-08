import 'dart:math';
import 'package:flutter/material.dart';
import '../../views/explorer/circle_of_fifths_wheel.dart';
import '../../models/music_constants.dart';

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
    // Parse currentKey (e.g., "C Major", "A Minor")
    final parts = currentKey.split(' ');
    final root = parts[0];
    final mode = parts.length > 1 ? parts[1] : 'Major';
    final isMinor = mode == 'Minor';

    // Find index
    final keys = MusicConstants.KEYS;
    int selectedIndex = 0;

    // keys 리스트에서 현재 root와 일치하는 키 찾기
    // MusicConstants.KEYS는 KeyData 객체 리스트라고 가정.
    // Major인 경우 name, Minor인 경우 minor 속성과 비교
    for (int i = 0; i < keys.length; i++) {
      if (isMinor) {
        if (keys[i].minor == root) {
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
            onTapUp: (details) {
              _handleTap(details, context, size / 2, keys);
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
                    fontSize: size * 0.15, // Scale font size
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.0,
                  ),
                ),
                Text(
                  mode.toUpperCase(),
                  style: TextStyle(
                    fontSize: size * 0.045, // Scale font size
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

  void _handleTap(TapUpDetails details, BuildContext context, double radius,
      List<KeyData> keys) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPos = box.globalToLocal(details.globalPosition);
    final Center = Offset(radius, radius);

    final dx = localPos.dx - Center.dx;
    final dy = localPos.dy - Center.dy;

    final dist = sqrt(dx * dx + dy * dy);

    // Radius values from Painter (scaled relative to size)
    // 0.45, 0.32, 0.15 relative to width (which is size)
    final rOuter = radius * 2 * 0.45;
    final rMiddle = radius * 2 * 0.32;
    final rInner = radius * 2 * 0.15;

    // Check click validity
    if (dist < rInner || dist > rOuter) return; // Clicked hole or outside

    bool isInner = dist < rMiddle;

    // Calculate Angle
    double angle = atan2(dy, dx); // -pi to pi
    double degrees = angle * 180 / pi; // -180 to 180

    // Adjust degrees to match painter logic:
    // Painter starts slice 0 at -90 deg.
    // Need to shift so -90 becomes 0 index.
    // angle = (index * 30 - 90)
    // index * 30 = angle + 90
    // index = (angle + 90) / 30

    double adjustedDegrees = degrees + 90;
    if (adjustedDegrees < 0) adjustedDegrees += 360;

    int index = (adjustedDegrees / 30).floor() % 12;

    // Get Key
    final keyData = keys[index];
    final scaleName = isInner ? keyData.minor : keyData.name;
    final modeName = isInner ? 'Minor' : 'Major';

    // Callback
    onKeySelected('$scaleName $modeName');
  }
}
