import 'package:flutter/material.dart';

// Mock classes to simulate the environment
class StudioState {
  int selectedBlockIndex = 0;
}

class ChordBlock {
  final String chordSymbol;
  final String? functionTag;
  ChordBlock(this.chordSymbol, {this.functionTag});
}

class ProgressionSession {
  final String key;
  final List<ChordBlock> progression;
  ProgressionSession({required this.key, required this.progression});
}

// The logic to test (extracted from _buildSoloingGuide)
String getScaleRecommendation(ProgressionSession session, int index) {
  final currentBlock = session.progression[index];
  final chord = currentBlock.chordSymbol;
  final function = currentBlock.functionTag;

  String scaleRecommendation = '';

  // 1. Function Tag Logic
  if (function != null) {
    if (function.contains('I') && !function.contains('V')) {
      scaleRecommendation = '${session.key} Major Scale (Ionian)';
    } else if (function.toLowerCase().contains('ii')) {
      scaleRecommendation = 'Dorian Mode';
    } else if (function == 'V' || function == 'V7') {
      scaleRecommendation = 'Mixolydian Mode';
    } else if (function.toLowerCase().contains('vi')) {
      scaleRecommendation = 'Aeolian Mode (Natural Minor)';
    }
  }

  // 2. Fallback Logic
  if (scaleRecommendation.isEmpty) {
    if (chord.contains('Maj7')) {
      scaleRecommendation = 'Major Scale / Lydian';
    } else if (chord.contains('m7')) {
      scaleRecommendation = 'Dorian / Minor Pentatonic';
    } else if (chord.contains('7')) {
      scaleRecommendation = 'Mixolydian / Minor Blues';
    } else {
      scaleRecommendation = '${session.key} Scale Note';
    }
  }

  return scaleRecommendation;
}

// Improved Logic to test
String getImprovedScaleRecommendation(ProgressionSession session, int index) {
  final currentBlock = session.progression[index];
  final chord = currentBlock.chordSymbol;
  final function = currentBlock.functionTag;

  bool isMinorKey = session.key.contains('m') && !session.key.contains('Maj');
  // Note: session.key might be "C Major" or "Am". Simple check for 'm' at end or lowercase 'm' followed by nothing/numbers.
  // Better: check if the key string implies minor.

  // Let's assume input format "A Minor" or "C Major"
  isMinorKey = session.key.toLowerCase().contains('minor');

  String scaleRecommendation = '';

  // 1. Special Case: Minor Key V7 (Harmonic Minor context)
  if (isMinorKey && (function == 'V' || function == 'V7')) {
    return 'Harmonic Minor Scale (Phrygian Dominant)';
  }

  // 2. Function Tag Logic
  if (function != null) {
    if (function.contains('I') && !function.contains('V')) {
      scaleRecommendation = isMinorKey
          ? '${session.key} Natural Minor (Aeolian)'
          : '${session.key} Major Scale (Ionian)';
    } else if (function.toLowerCase().contains('ii')) {
      // ii in Major is Dorian, ii in Minor (often m7b5) is Locrian
      if (chord.contains('b5')) {
        scaleRecommendation = 'Locrian Mode';
      } else {
        scaleRecommendation = 'Dorian Mode';
      }
    } else if (function == 'V' || function == 'V7') {
      scaleRecommendation = 'Mixolydian Mode';
    } else if (function.toLowerCase().contains('vi')) {
      scaleRecommendation = 'Aeolian Mode (Natural Minor)';
    }
  }

  // 3. Fallback Logic
  if (scaleRecommendation.isEmpty) {
    if (chord.contains('Maj7')) {
      scaleRecommendation = 'Major Scale / Lydian';
    } else if (chord.contains('m7b5')) {
      scaleRecommendation = 'Locrian Mode';
    } else if (chord.contains('m7')) {
      scaleRecommendation = 'Dorian / Minor Pentatonic';
    } else if (chord.contains('7')) {
      // Check if it resolves to a minor chord? (Too complex for simple check, assume Mixolydian unless key is minor)
      scaleRecommendation = 'Mixolydian / Minor Blues';
    } else if (chord.contains('dim7')) {
      scaleRecommendation = 'Diminished Scale';
    } else {
      scaleRecommendation = '${session.key} Scale Note';
    }
  }

  return scaleRecommendation;
}

void main() {
  // Test Case: Am Key, A Harmonic Minor Progression (Am - Dm - E7 - Am)
  // Note: Key string format assumed based on app usage ("C Major", "A Minor")
  final session = ProgressionSession(key: 'A Minor', progression: [
    ChordBlock('Am7', functionTag: 'i'),
    ChordBlock('Bm7b5', functionTag: 'ii°'), // or ii
    ChordBlock('E7', functionTag: 'V'),
    ChordBlock('Am7', functionTag: 'i'),
  ]);

  print('--- Current Logic Results ---');
  for (int i = 0; i < session.progression.length; i++) {
    print(
        'Chord: ${session.progression[i].chordSymbol} (${session.progression[i].functionTag}) -> ${getScaleRecommendation(session, i)}');
  }

  print('\n--- Improved Logic Results ---');
  for (int i = 0; i < session.progression.length; i++) {
    print(
        'Chord: ${session.progression[i].chordSymbol} (${session.progression[i].functionTag}) -> ${getImprovedScaleRecommendation(session, i)}');
  }
}
