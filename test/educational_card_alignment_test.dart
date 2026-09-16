import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/information/presentation/models/educational_content.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/educational_content_widgets.dart';

void main() {
  testWidgets(
    'one-line and two-line educational cards share the same baseline',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                EducationalContentCard(
                  content: educationalContents[0],
                  selected: true,
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                EducationalContentCard(
                  content: educationalContents[4],
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final cards = find.byType(EducationalContentCard);
      expect(
        tester.getSize(cards.first).height,
        tester.getSize(cards.last).height,
      );
      final markers = find.byType(AnimatedContainer);
      expect(
        tester.getTopLeft(markers.first).dy,
        tester.getTopLeft(markers.last).dy,
      );
      expect(
        tester.getTopLeft(cards.first).dy,
        tester.getTopLeft(cards.last).dy,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
