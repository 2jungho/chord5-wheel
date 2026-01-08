import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_state.dart';
import '../models/music_constants.dart';
import '../utils/theory_utils.dart';

class AICommand {
  final String command;
  final Map<String, dynamic> params;

  AICommand({required this.command, required this.params});

  @override
  String toString() => 'AICommand(command: $command, params: $params)';
}

class AICommandService {
  /// 텍스트에서 JSON 명령 블록을 추출합니다.
  static AICommand? parse(String text) {
    try {
      final jsonRegex = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```');
      final match = jsonRegex.firstMatch(text);

      if (match != null) {
        final jsonStr = match.group(1)!;
        final Map<String, dynamic> data = jsonDecode(jsonStr);

        if (data.containsKey('command')) {
          return AICommand(
            command: data['command'],
            params: data['params'] ?? {},
          );
        }
      }
    } catch (e) {
      debugPrint('AI Command Parsing Error: $e');
    }
    return null;
  }

  /// 명령을 실행합니다.
  static void execute(BuildContext context, AICommand cmd) {
    final musicState = context.read<MusicState>();
    debugPrint('Executing AI Command: ${cmd.command}');

    switch (cmd.command) {
      case 'set_key':
        _executeSetKey(musicState, cmd.params);
        break;
      case 'set_mode':
        _executeSetMode(musicState, cmd.params);
        break;
      default:
        debugPrint('Unknown command: ${cmd.command}');
    }
  }

  static void _executeSetKey(MusicState state, Map<String, dynamic> params) {
    String? keyStr = params['key'];
    if (keyStr == null) return;

    // "C Major", "Am", "F# Minor" 등 파싱
    // TheoryUtils나 MusicState 로직 활용
    // MusicState는 Key Index와 Inner/Outer Ring 상태를 받음.

    // 1. Root Note & Mode 추출
    final parts = keyStr.split(' ');
    String root = parts[0];
    String mode = parts.length > 1 ? parts[1] : 'Major';

    // Normalize Root (e.g. Am -> A, m handled by mode)
    if (root.endsWith('m') && root.length > 1 && root[1] != 'a' && root[1] != 'l') {
       // 'm' suffix removal (simple check)
       // But 'Am' -> 'A'. 'Dim' -> 'Di'.
       // Better logic:
       // If parts length is 1 and it ends with m, it's minor.
    }
    
    // Simple parsing logic:
    // If input is "Am", parts=["Am"].
    // If input is "C Minor", parts=["C", "Minor"].
    
    bool isMinor = false;
    
    if (mode.toLowerCase().contains('minor') || mode == 'm') {
      isMinor = true;
    } else if (root.endsWith('m') && !root.contains('aj')) { 
      // e.g. Am (but not Amaj7)
      isMinor = true;
      root = root.substring(0, root.length - 1);
    }

    // Normalize Root Note
    root = TheoryUtils.normalizeNoteName(root);

    // Find Key Index in MusicConstants.KEYS
    int keyIndex = -1;
    
    // Search in Major names first
    for (int i = 0; i < MusicConstants.KEYS.length; i++) {
      if (MusicConstants.KEYS[i].name == root) {
        keyIndex = i;
        if (isMinor) {
             // If user said "C Minor", but meant relative minor of Eb?
             // Usually "Set key to C Minor" means Parallel Minor (Inner Ring of Eb Major Key? No)
             // Inner Ring of a slice is the Relative Minor.
             // Slice 0 (C Major) -> Inner is A Minor.
             
             // If user wants C Minor (Eb Major relative), we need to find slice where Inner is C.
        }
        break;
      }
    }

    // If target is Minor, we need to find which Slice has this note as Minor (Inner)
    if (isMinor) {
       keyIndex = -1;
       for (int i = 0; i < MusicConstants.KEYS.length; i++) {
         if (MusicConstants.KEYS[i].minor == root + 'm' || MusicConstants.KEYS[i].minor == root) {
           keyIndex = i;
           break;
         }
         // Check without 'm'
         if (MusicConstants.KEYS[i].minor.replaceAll('m','') == root) {
           keyIndex = i;
           break;
         }
       }
    } else {
       // Major Target
       for (int i = 0; i < MusicConstants.KEYS.length; i++) {
         if (MusicConstants.KEYS[i].name == root) {
           keyIndex = i;
           break;
         }
       }
    }

    if (keyIndex != -1) {
      state.selectKeySlice(keyIndex, isMinor);
    } else {
      debugPrint('Key not found: $keyStr');
    }
  }

  static void _executeSetMode(MusicState state, Map<String, dynamic> params) {
    String? modeStr = params['mode'];
    if (modeStr == null) return;

    // Find mode index
    int modeIndex = -1;
    for (int i = 0; i < MusicConstants.MODES.length; i++) {
      if (MusicConstants.MODES[i].name.toLowerCase() == modeStr.toLowerCase()) {
        modeIndex = i;
        break;
      }
    }

    if (modeIndex != -1) {
      state.changeMode(modeIndex);
    }
  }
}
