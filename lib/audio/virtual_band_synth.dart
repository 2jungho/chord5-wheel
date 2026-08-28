import 'dart:math';
import 'dart:typed_data';

enum DrumSound {
  kick,
  snare,
  hiHatClosed,
  hiHatOpen,
  rimshot,
}

class VirtualBandSynth {
  static const int sampleRate = 44100;

  /// Generate a valid 16-bit Mono WAV file from floating-point audio samples (-1.0 to 1.0)
  static Uint8List createWav(List<double> samples, {int rate = sampleRate}) {
    final int numSamples = samples.length;
    final int byteRate = rate * 2; // 16-bit mono = 2 bytes per sample
    final int dataSize = numSamples * 2;
    final int fileSize = 36 + dataSize;

    final buffer = Uint8List(44 + dataSize);
    final view = ByteData.view(buffer.buffer);

    // RIFF header
    _writeString(view, 0, 'RIFF');
    view.setUint32(4, fileSize, Endian.little);
    _writeString(view, 8, 'WAVE');

    // fmt subchunk
    _writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    view.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    view.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    view.setUint32(24, rate, Endian.little); // SampleRate
    view.setUint32(28, byteRate, Endian.little); // ByteRate
    view.setUint16(32, 2, Endian.little); // BlockAlign (NumChannels * BitsPerSample/8)
    view.setUint16(34, 16, Endian.little); // BitsPerSample

    // data subchunk
    _writeString(view, 36, 'data');
    view.setUint32(40, dataSize, Endian.little);

    // 16-bit PCM sample data
    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final sample = samples[i].clamp(-1.0, 1.0);
      final int intSample = (sample * 32767.0).round().clamp(-32768, 32767);
      view.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer;
  }

  static void _writeString(ByteData view, int offset, String text) {
    for (int i = 0; i < text.length; i++) {
      view.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  // --- Drum Synthesizers ---

  /// Punchy Kick Drum (Pitch envelope 150Hz -> 42Hz + Click transient)
  /// Punchy Kick Drum (Pitch envelope 140Hz -> 38Hz + Click transient + Analog Saturation)
  static Uint8List generateKick() {
    const double duration = 0.32;
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double phase = 0.0;
    final random = Random(42);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      // Exponential pitch drop from 140Hz down to deep 38Hz sub
      final freq = 38.0 + 102.0 * exp(-22.0 * progress);
      phase += 2.0 * pi * freq / sampleRate;

      // Amplitude envelope: snappy punch + smooth sub decay
      final ampEnv = exp(-7.5 * progress);

      // Body sine wave with analog warmth
      double s = sin(phase) * ampEnv;

      // Add click attack at the very beginning (first 6ms) for acoustic beater slap
      if (t < 0.006) {
        final clickEnv = 1.0 - (t / 0.006);
        s += (random.nextDouble() * 2.0 - 1.0) * 0.45 * clickEnv;
      }

      // Soft tape distortion for punchy low-end
      samples[i] = (s * 1.35 / (1.0 + (s.abs() * 0.35))).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  /// Snappy Snare Drum (Tuned shell 190Hz + Filtered warm snare wire sizzle)
  static Uint8List generateSnare() {
    const double duration = 0.24;
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double tonePhase = 0.0;
    final random = Random(123);
    double lastNoise = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      // Shell body tone (190Hz -> 135Hz)
      final toneFreq = 135.0 + 55.0 * exp(-24.0 * progress);
      tonePhase += 2.0 * pi * toneFreq / sampleRate;
      final toneAmp = exp(-16.0 * progress) * 0.65;
      final toneSample = sin(tonePhase) * toneAmp;

      // Snare wire sizzle (Pink/High-pass filtered noise)
      final rawNoise = random.nextDouble() * 2.0 - 1.0;
      final noiseHp = 0.72 * (rawNoise - lastNoise);
      lastNoise = rawNoise;

      final noiseAmp = exp(-11.0 * progress) * 0.70;
      final noiseSample = noiseHp * noiseAmp;

      // Combine body + wires
      final combined = toneSample + noiseSample;
      samples[i] = (combined / (1.0 + (combined.abs() * 0.25))).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  /// Crisp Closed Hi-Hat (Metallic inharmonic cluster with crisp high-end)
  static Uint8List generateHiHatClosed() {
    const double duration = 0.050;
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    final random = Random(789);
    double p1 = 0.0, p2 = 0.0, p3 = 0.0;
    double lastNoise = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      // Metallic inharmonic frequencies
      p1 += 2.0 * pi * 5870.0 / sampleRate;
      p2 += 2.0 * pi * 8450.0 / sampleRate;
      p3 += 2.0 * pi * 11200.0 / sampleRate;

      final metallic = (sin(p1) + sin(p2) * 0.7 + sin(p3) * 0.5) * 0.32;
      final rawNoise = random.nextDouble() * 2.0 - 1.0;
      final noise = (rawNoise - lastNoise) * 0.75;
      lastNoise = rawNoise;

      final amp = exp(-45.0 * progress);
      samples[i] = ((metallic + noise) * amp * 0.85).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  /// Open Hi-Hat (Sustained shimmering cymbal sizzle)
  static Uint8List generateHiHatOpen() {
    const double duration = 0.38;
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    final random = Random(456);
    double p1 = 0.0, p2 = 0.0, p3 = 0.0;
    double lastNoise = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      p1 += 2.0 * pi * 5870.0 / sampleRate;
      p2 += 2.0 * pi * 8450.0 / sampleRate;
      p3 += 2.0 * pi * 11200.0 / sampleRate;

      final metallic = (sin(p1) + sin(p2) * 0.7 + sin(p3) * 0.5) * 0.28;
      final rawNoise = random.nextDouble() * 2.0 - 1.0;
      final noise = (rawNoise - lastNoise) * 0.75;
      lastNoise = rawNoise;

      final amp = exp(-7.5 * progress);
      samples[i] = ((metallic + noise) * amp * 0.80).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  /// Rimshot / Acoustic Cross-stick click
  static Uint8List generateRimshot() {
    const double duration = 0.065;
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double phase = 0.0;
    final random = Random(999);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      phase += 2.0 * pi * 880.0 / sampleRate;
      final woodTone = sin(phase) * exp(-35.0 * progress) * 0.65;
      final noise = (random.nextDouble() * 2.0 - 1.0) * exp(-50.0 * progress) * 0.35;

      samples[i] = (woodTone + noise).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  // --- Bass Synthesizer ---

  /// Rich Electric Bass Note (Warm fundamental + 2nd & 3rd harmonics + analog warmth)
  static Uint8List generateBassNote(double freqHz, {double duration = 0.65}) {
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double p1 = 0.0, p2 = 0.0, p3 = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;

      p1 += 2.0 * pi * freqHz / sampleRate;
      p2 += 2.0 * pi * (freqHz * 2.0) / sampleRate;
      p3 += 2.0 * pi * (freqHz * 3.0) / sampleRate;

      // ADSR Envelope: Fast attack (8ms), decay to rich warm sustain
      double env;
      if (t < 0.008) {
        env = t / 0.008;
      } else {
        env = exp(-2.8 * (t - 0.008));
      }

      // Harmonic content: strong fundamental + warm octaves
      final raw = sin(p1) * 0.80 + sin(p2) * 0.32 + sin(p3) * 0.10;

      // Soft saturation for vintage tube bass warmth
      final saturated = raw / (1.0 + (raw.abs() * 0.35));

      samples[i] = (saturated * env * 0.92).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  // --- Keyboard / Electric Piano (Rhodes Style) Synthesizer ---

  /// Bell-like FM Electric Piano chord note (Carrier + Modulator + warm stereo chime)
  static Uint8List generateKeyboardNote(double freqHz, {double duration = 1.2}) {
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double modPhase = 0.0;
    double carPhase = 0.0;
    final modFreq = freqHz * 2.0; // 2:1 FM ratio for classic Rhodes bell chime

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      // FM Modulation index decays over time (sparkling attack -> mellow warm sustain)
      final modIndex = 1.4 * exp(-4.5 * progress);
      modPhase += 2.0 * pi * modFreq / sampleRate;
      final modSample = sin(modPhase) * modIndex;

      // Carrier
      carPhase += 2.0 * pi * freqHz / sampleRate;
      final carSample = sin(carPhase + modSample);

      // Amplitude Envelope
      double env;
      if (t < 0.012) {
        env = t / 0.012;
      } else {
        env = exp(-1.9 * (t - 0.012));
      }

      // Add gentle warm overtone
      final overtone = sin(carPhase * 3.0) * 0.06 * exp(-5.0 * progress);

      samples[i] = ((carSample * 0.82 + overtone) * env * 0.88).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }


  /// Note name to Frequency helper (A4 = 440Hz)
  static double noteToFrequency(String noteName, int octave) {
    const noteIndices = {
      'C': 0, 'C#': 1, 'Db': 1,
      'D': 2, 'D#': 3, 'Eb': 3,
      'E': 4, 'Fb': 4, 'E#': 5,
      'F': 5, 'F#': 6, 'Gb': 6,
      'G': 7, 'G#': 8, 'Ab': 8,
      'A': 9, 'A#': 10, 'Bb': 10,
      'B': 11, 'Cb': 11, 'B#': 0,
    };

    final semitone = noteIndices[noteName] ?? 0;
    // MIDI note number: C0 = 12, A4 = 69 (C4 = 60)
    final midi = (octave + 1) * 12 + semitone;
    return 440.0 * pow(2.0, (midi - 69) / 12.0);
  }
}
