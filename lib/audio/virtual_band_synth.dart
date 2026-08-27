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
  static Uint8List generateKick() {
    const double duration = 0.28;
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double phase = 0.0;
    final random = Random(42);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      // Exponential pitch drop
      final freq = 42.0 + 110.0 * exp(-18.0 * progress);
      phase += 2.0 * pi * freq / sampleRate;

      // Amplitude envelope
      final ampEnv = exp(-9.0 * progress);

      // Body sine wave with gentle soft clipping/warmth
      double s = sin(phase) * ampEnv;

      // Add click attack at the very beginning (first 5ms)
      if (t < 0.008) {
        final clickEnv = 1.0 - (t / 0.008);
        s += (random.nextDouble() * 2.0 - 1.0) * 0.4 * clickEnv;
      }

      // Soft distortion for punch
      samples[i] = (s * 1.3).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  /// Snappy Snare Drum (Tuned body 185Hz + Filtered white noise burst)
  static Uint8List generateSnare() {
    const double duration = 0.22;
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double tonePhase = 0.0;
    final random = Random(123);
    double lastNoise = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      // Tone part (decaying 185Hz -> 130Hz)
      final toneFreq = 130.0 + 55.0 * exp(-20.0 * progress);
      tonePhase += 2.0 * pi * toneFreq / sampleRate;
      final toneAmp = exp(-18.0 * progress) * 0.6;
      final toneSample = sin(tonePhase) * toneAmp;

      // Noise part (white noise through high-pass filter)
      final rawNoise = random.nextDouble() * 2.0 - 1.0;
      final noiseHp = 0.7 * (rawNoise - lastNoise);
      lastNoise = rawNoise;

      final noiseAmp = exp(-12.0 * progress) * 0.75;
      final noiseSample = noiseHp * noiseAmp;

      // Combine
      samples[i] = (toneSample + noiseSample).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  /// Crisp Closed Hi-Hat (Metallic high frequency burst)
  static Uint8List generateHiHatClosed() {
    const double duration = 0.055;
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    final random = Random(789);
    double p1 = 0.0, p2 = 0.0, p3 = 0.0;
    double lastNoise = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      // Metallic ring frequencies (inharmonic)
      p1 += 2.0 * pi * 5870.0 / sampleRate;
      p2 += 2.0 * pi * 8450.0 / sampleRate;
      p3 += 2.0 * pi * 11200.0 / sampleRate;

      final metallic = (sin(p1) + sin(p2) * 0.7 + sin(p3) * 0.5) * 0.3;
      final rawNoise = random.nextDouble() * 2.0 - 1.0;
      final noise = (rawNoise - lastNoise) * 0.7;
      lastNoise = rawNoise;

      final amp = exp(-40.0 * progress);
      samples[i] = ((metallic + noise) * amp * 0.85).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  /// Open Hi-Hat (Sustained metallic cymbal sizzle)
  static Uint8List generateHiHatOpen() {
    const double duration = 0.35;
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

      final metallic = (sin(p1) + sin(p2) * 0.7 + sin(p3) * 0.5) * 0.25;
      final rawNoise = random.nextDouble() * 2.0 - 1.0;
      final noise = (rawNoise - lastNoise) * 0.75;
      lastNoise = rawNoise;

      final amp = exp(-8.0 * progress);
      samples[i] = ((metallic + noise) * amp * 0.75).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  /// Rimshot / Percussion click
  static Uint8List generateRimshot() {
    const double duration = 0.07;
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double phase = 0.0;
    final random = Random(999);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      phase += 2.0 * pi * 800.0 / sampleRate;
      final woodTone = sin(phase) * exp(-30.0 * progress) * 0.6;
      final noise = (random.nextDouble() * 2.0 - 1.0) * exp(-45.0 * progress) * 0.4;

      samples[i] = (woodTone + noise).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  // --- Bass Synthesizer ---

  /// Rich Electric Bass Note (Warm fundamental + 2nd & 3rd harmonics + smooth envelope)
  static Uint8List generateBassNote(double freqHz, {double duration = 0.6}) {
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double p1 = 0.0, p2 = 0.0, p3 = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;

      p1 += 2.0 * pi * freqHz / sampleRate;
      p2 += 2.0 * pi * (freqHz * 2.0) / sampleRate;
      p3 += 2.0 * pi * (freqHz * 3.0) / sampleRate;

      // ADSR Envelope: Fast attack (10ms), decay to sustain, smooth release
      double env;
      if (t < 0.012) {
        env = t / 0.012;
      } else {
        env = exp(-3.2 * (t - 0.012));
      }

      // Harmonic content: strong fundamental + warm octaves
      final raw = sin(p1) * 0.75 + sin(p2) * 0.35 + sin(p3) * 0.12;

      // Soft saturation for analog bass warmth
      final saturated = raw / (1.0 + (raw.abs() * 0.4));

      samples[i] = (saturated * env * 0.9).clamp(-0.95, 0.95);
    }

    return createWav(samples);
  }

  // --- Keyboard / Electric Piano (Rhodes Style) Synthesizer ---

  /// Bell-like FM Electric Piano chord note (Carrier + Modulator + warm release)
  static Uint8List generateKeyboardNote(double freqHz, {double duration = 1.0}) {
    final int totalSamples = (sampleRate * duration).round();
    final samples = List<double>.filled(totalSamples, 0.0);

    double modPhase = 0.0;
    double carPhase = 0.0;
    final modFreq = freqHz * 2.0; // 2:1 FM ratio for Rhodes chime

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = t / duration;

      // FM Modulation index decays over time (bright attack -> warm mellow sustain)
      final modIndex = 1.6 * exp(-5.0 * progress);
      modPhase += 2.0 * pi * modFreq / sampleRate;
      final modSample = sin(modPhase) * modIndex;

      // Carrier
      carPhase += 2.0 * pi * freqHz / sampleRate;
      final carSample = sin(carPhase + modSample);

      // Amplitude Envelope
      double env;
      if (t < 0.015) {
        env = t / 0.015;
      } else {
        env = exp(-2.2 * (t - 0.015));
      }

      // Add gentle acoustic overtone
      final overtone = sin(carPhase * 3.0) * 0.08 * exp(-6.0 * progress);

      samples[i] = ((carSample * 0.8 + overtone) * env * 0.85).clamp(-0.95, 0.95);
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
