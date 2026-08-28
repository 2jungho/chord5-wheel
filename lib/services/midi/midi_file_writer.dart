import 'dart:typed_data';

/// Variable-Length Quantity (VLQ) 인코더 및 MIDI 바이트 빌더
class MidiBuffer {
  final List<int> _bytes = [];

  Uint8List toUint8List() => Uint8List.fromList(_bytes);

  void addByte(int b) => _bytes.add(b & 0xFF);

  void addBytes(List<int> bytes) => _bytes.addAll(bytes.map((b) => b & 0xFF));

  void addUint16(int value) {
    _bytes.add((value >> 8) & 0xFF);
    _bytes.add(value & 0xFF);
  }

  void addUint32(int value) {
    _bytes.add((value >> 24) & 0xFF);
    _bytes.add((value >> 16) & 0xFF);
    _bytes.add((value >> 8) & 0xFF);
    _bytes.add(value & 0xFF);
  }

  void addVLQ(int value) {
    int buffer = value & 0x7F;
    while ((value >>= 7) > 0) {
      buffer <<= 8;
      buffer |= 0x80;
      buffer += (value & 0x7F);
    }
    while (true) {
      _bytes.add(buffer & 0xFF);
      if ((buffer & 0x80) != 0) {
        buffer >>= 8;
      } else {
        break;
      }
    }
  }
}

class MidiTrack {
  final String name;
  final MidiBuffer _events = MidiBuffer();
  int _lastTick = 0;

  MidiTrack({required this.name}) {
    // Track Name Meta Event (Delta-time 0, 0xFF, 0x03, len, string)
    _events.addVLQ(0);
    _events.addByte(0xFF);
    _events.addByte(0x03);
    final nameBytes = name.codeUnits;
    _events.addVLQ(nameBytes.length);
    _events.addBytes(nameBytes);
  }

  void addTempo({required int atTick, required int bpm}) {
    final delta = (atTick - _lastTick).clamp(0, 0x0FFFFFFF);
    _lastTick = atTick;

    _events.addVLQ(delta);
    _events.addByte(0xFF);
    _events.addByte(0x51);
    _events.addByte(0x03);

    // Microseconds per quarter note = 60,000,000 / BPM
    final mpqn = (60000000 / bpm.clamp(20, 300)).round();
    _events.addByte((mpqn >> 16) & 0xFF);
    _events.addByte((mpqn >> 8) & 0xFF);
    _events.addByte(mpqn & 0xFF);
  }

  void addTimeSignature({required int atTick, int numerator = 4, int denominator = 4}) {
    final delta = (atTick - _lastTick).clamp(0, 0x0FFFFFFF);
    _lastTick = atTick;

    _events.addVLQ(delta);
    _events.addByte(0xFF);
    _events.addByte(0x58);
    _events.addByte(0x04);
    _events.addByte(numerator);
    // Denominator is expressed as power of 2 (4 = 2^2 -> 2)
    int denomPower = 2;
    if (denominator == 8) denomPower = 3;
    if (denominator == 2) denomPower = 1;
    _events.addByte(denomPower);
    _events.addByte(24); // MIDI clocks per metronome click
    _events.addByte(8);  // 32nd notes per 24 MIDI clocks
  }

  void addNoteOn({
    required int atTick,
    required int channel, // 0 - 15
    required int midiNote, // 0 - 127
    required int velocity, // 1 - 127
  }) {
    final delta = (atTick - _lastTick).clamp(0, 0x0FFFFFFF);
    _lastTick = atTick;

    _events.addVLQ(delta);
    _events.addByte(0x90 | (channel & 0x0F));
    _events.addByte(midiNote.clamp(0, 127));
    _events.addByte(velocity.clamp(1, 127));
  }

  void addNoteOff({
    required int atTick,
    required int channel,
    required int midiNote,
    int velocity = 64,
  }) {
    final delta = (atTick - _lastTick).clamp(0, 0x0FFFFFFF);
    _lastTick = atTick;

    _events.addVLQ(delta);
    _events.addByte(0x80 | (channel & 0x0F));
    _events.addByte(midiNote.clamp(0, 127));
    _events.addByte(velocity.clamp(0, 127));
  }

  Uint8List buildTrackChunk() {
    final trackChunk = MidiBuffer();
    // 'MTrk'
    trackChunk.addBytes([0x4D, 0x54, 0x72, 0x6B]);

    // End of Track Event (Delta-time 0, 0xFF, 0x2F, 0x00)
    _events.addVLQ(0);
    _events.addByte(0xFF);
    _events.addByte(0x2F);
    _events.addByte(0x00);

    final eventBytes = _events.toUint8List();
    trackChunk.addUint32(eventBytes.length);
    trackChunk.addBytes(eventBytes);

    return trackChunk.toUint8List();
  }
}

class MidiFileWriter {
  final int ticksPerQuarterNote;
  final List<MidiTrack> _tracks = [];

  MidiFileWriter({this.ticksPerQuarterNote = 480});

  MidiTrack createTrack(String name) {
    final track = MidiTrack(name: name);
    _tracks.add(track);
    return track;
  }

  Uint8List buildMidiFile() {
    final fileBuffer = MidiBuffer();

    // 1. Header Chunk 'MThd'
    fileBuffer.addBytes([0x4D, 0x54, 0x68, 0x64]); // 'MThd'
    fileBuffer.addUint32(6); // Chunk length = 6
    fileBuffer.addUint16(1); // Format 1 (Multi-track Synchronous)
    fileBuffer.addUint16(_tracks.length); // Track count
    fileBuffer.addUint16(ticksPerQuarterNote); // Division (PPQN)

    // 2. Track Chunks 'MTrk'
    for (var track in _tracks) {
      fileBuffer.addBytes(track.buildTrackChunk());
    }

    return fileBuffer.toUint8List();
  }
}
