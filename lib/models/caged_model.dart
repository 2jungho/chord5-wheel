class CagedPattern {
  final String name;
  final String cagedName;
  final int baseOffset;
  final int rootString;
  final List<CagedDot> dots;

  const CagedPattern({
    required this.name,
    required this.cagedName,
    required this.baseOffset,
    required this.rootString,
    required this.dots,
  });
}

class CagedDot {
  final int s;
  final int o;
  final String i;
  const CagedDot({required this.s, required this.o, required this.i});
}

// Major CAGED Patterns (Chord Tones: 1, 3, 5)
const List<CagedPattern> majorCagedPatterns = [
  CagedPattern(
      name: "Position 1",
      cagedName: "E Form",
      baseOffset: 0,
      rootString: 6,
      dots: [
        CagedDot(s: 6, o: 0, i: '1'),
        CagedDot(s: 5, o: 2, i: '5'),
        CagedDot(s: 4, o: 2, i: '1'),
        CagedDot(s: 3, o: 1, i: '3'),
        CagedDot(s: 2, o: 0, i: '5'),
        CagedDot(s: 1, o: 0, i: '1'),
      ]),
  CagedPattern(
      name: "Position 2",
      cagedName: "D Form",
      baseOffset: 2,
      rootString: 4,
      dots: [
        CagedDot(s: 4, o: 0, i: '1'),
        CagedDot(s: 3, o: 2, i: '5'),
        CagedDot(s: 2, o: 3, i: '1'),
        CagedDot(s: 1, o: 2, i: '3'),
      ]),
  CagedPattern(
      name: "Position 3",
      cagedName: "C Form",
      baseOffset: 4,
      rootString: 5,
      dots: [
        CagedDot(s: 5, o: 3, i: '1'),
        CagedDot(s: 4, o: 2, i: '3'),
        CagedDot(s: 3, o: 0, i: '5'),
        CagedDot(s: 2, o: 1, i: '1'),
        CagedDot(s: 1, o: 0, i: '3'),
      ]),
  CagedPattern(
      name: "Position 4",
      cagedName: "A Form",
      baseOffset: 7,
      rootString: 5,
      dots: [
        CagedDot(s: 5, o: 0, i: '1'),
        CagedDot(s: 4, o: 2, i: '5'),
        CagedDot(s: 3, o: 2, i: '1'),
        CagedDot(s: 2, o: 2, i: '3'),
        CagedDot(s: 1, o: 0, i: '5'),
      ]),
  CagedPattern(
      name: "Position 5",
      cagedName: "G Form",
      baseOffset: 9,
      rootString: 6,
      dots: [
        CagedDot(s: 6, o: 3, i: '1'),
        CagedDot(s: 5, o: 2, i: '3'),
        CagedDot(s: 4, o: 0, i: '5'),
        CagedDot(s: 3, o: 0, i: '1'),
        CagedDot(s: 2, o: 0, i: '3'),
        CagedDot(s: 1, o: 3, i: '1'),
      ]),
];

// Minor CAGED Patterns (Chord Tones: 1, b3, 5)
const List<CagedPattern> minorCagedPatterns = [
  CagedPattern(
      name: "Position 1",
      cagedName: "Em Form",
      baseOffset: 0,
      rootString: 6,
      dots: [
        CagedDot(s: 6, o: 0, i: '1'),
        CagedDot(s: 5, o: 2, i: '5'),
        CagedDot(s: 4, o: 2, i: '1'),
        CagedDot(s: 3, o: 0, i: 'b3'),
        CagedDot(s: 2, o: 0, i: '5'),
        CagedDot(s: 1, o: 0, i: '1'),
      ]),
  CagedPattern(
      name: "Position 2",
      cagedName: "Dm Form",
      baseOffset: 2,
      rootString: 4,
      dots: [
        CagedDot(s: 4, o: 0, i: '1'),
        CagedDot(s: 3, o: 2, i: '5'),
        CagedDot(s: 2, o: 3, i: '1'),
        CagedDot(s: 1, o: 1, i: 'b3'),
      ]),
  CagedPattern(
      name: "Position 3",
      cagedName: "Cm Form",
      baseOffset: 4,
      rootString: 5,
      dots: [
        CagedDot(s: 5, o: 3, i: '1'),
        CagedDot(s: 4, o: 5, i: '5'),
        CagedDot(s: 3, o: 5, i: '1'),
        CagedDot(s: 2, o: 4, i: 'b3'),
        CagedDot(s: 1, o: 3, i: '5'),
      ]),
  CagedPattern(
      name: "Position 4",
      cagedName: "Am Form",
      baseOffset: 7,
      rootString: 5,
      dots: [
        CagedDot(s: 5, o: 0, i: '1'),
        CagedDot(s: 4, o: 2, i: '5'),
        CagedDot(s: 3, o: 2, i: '1'),
        CagedDot(s: 2, o: 1, i: 'b3'),
        CagedDot(s: 1, o: 0, i: '5'),
      ]),
  CagedPattern(
      name: "Position 5",
      cagedName: "Gm Form",
      baseOffset: 9,
      rootString: 6,
      dots: [
        CagedDot(s: 6, o: 3, i: '1'),
        CagedDot(s: 5, o: 1, i: 'b3'),
        CagedDot(s: 4, o: 0, i: '5'),
        CagedDot(s: 3, o: 0, i: '1'),
        CagedDot(s: 2, o: 3, i: '5'),
        CagedDot(s: 1, o: 3, i: '1'),
      ]),
];
