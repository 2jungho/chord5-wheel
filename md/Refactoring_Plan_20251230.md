# Refactoring Plan (2025-12-30)

Based on the analysis of the `guitar_theory_app` codebase, the following areas have been identified for improvement. This plan aims to enhance maintainability, scalability, and testability.

## 1. Utility Refactoring (High Priority)

Currently, `TheoryUtils` and `GuitarUtils` are monolithic classes handling multiple distinct responsibilities.

### 1.1 Split `TheoryUtils`
*   **Target:** `lib/utils/theory_utils.dart`
*   **Proposed Structure:**
    *   `lib/utils/theory/scale_utils.dart`: Scale calculation, pattern definitions.
    *   `lib/utils/theory/chord_utils.dart`: Chord parsing, quality analysis, substitution logic.
    *   `lib/utils/theory/progression_utils.dart`: Parsing chord progressions, function analysis.
    *   `lib/utils/theory/note_utils.dart`: Basic note indexing, transposing, normalization.
    *   `lib/utils/theory_utils.dart`: (Optional) Re-export the above for backward compatibility during transition.

### 1.2 Split `GuitarUtils`
*   **Target:** `lib/utils/guitar_utils.dart`
*   **Proposed Structure:**
    *   `lib/utils/guitar/tuning_utils.dart`: String tuning, fret mapping.
    *   `lib/utils/guitar/voicing_generator.dart`: CAGED, Drop, Shell voicing generation algorithms.
    *   `lib/utils/guitar/fretboard_mapper.dart`: Generating `FretboardMarker` maps, handling ghost notes.
    *   `lib/utils/guitar/voice_leading.dart`: Voice leading calculation logic.

## 2. State Management & Logic Separation (Medium Priority)

`MusicState` contains significant business logic that should be separated from the view state.

### 2.1 Extract Service Layer
*   **Target:** `lib/providers/music_state.dart`
*   **Action:** Move calculation logic (`_calculateState`, `_calculateMainChordVoicing`) to a stateless service or utility class.
*   **Benefit:** Allows testing the logic independently of the Flutter framework and Provider.

## 3. Testing Strategy (Medium Priority)

Current tests are minimal and focused on specific verification scripts.

*   **Action:** Create proper unit tests for the newly extracted utility classes.
    *   Test scale generation for all keys and modes.
    *   Test chord parsing for complex symbols.
    *   Test voicing generation for consistency.

## 4. UI/View Optimizations (Low Priority)

*   **Target:** `StudioView` logic.
*   **Action:** Extract the `highlightMap` generation logic (handling chord tones + pentatonic ghost notes) into a `StudioViewModel` or helper to keep the Widget `build` method clean.

---

## Execution Strategy

1.  **Phase 1**: Refactor `TheoryUtils`. Create the new directory structure and move logic piece by piece, ensuring existing tests pass.
2.  **Phase 2**: Refactor `GuitarUtils`. Similar approach.
3.  **Phase 3**: Update import statements across the app to use new locations.
4.  **Phase 4**: Add Unit Tests for the new smaller utility classes.
