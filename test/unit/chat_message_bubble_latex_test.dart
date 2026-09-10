import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:guitar_theory_app/widgets/ai_chat/chat_message_bubble.dart';

void main() {
  testWidgets('ChatMessageBubble renders LaTeX arrows and math formulas correctly',
      (WidgetTester tester) async {
    const testMessage = r'''
음악 이론 진행:
1. 기본 진행: C $\rightarrow$ G $\rightarrow$ Am $\rightarrow$ F
2. 또 다른 표기: I $\to$ V $\to$ vi $\to$ IV
3. 블록 수식:
$$
\text{Dominant} \Rightarrow \text{Tonic}
$$
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: testMessage,
            isUser: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Math widget is rendered for the LaTeX syntax
    expect(find.byType(Math), findsWidgets);
  });
}
