import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ternatelomba/config/appTheme.dart';
import 'package:ternatelomba/design_system/tl_playful.dart';
import 'package:ternatelomba/design_system/tl_conversation.dart';
import 'package:ternatelomba/widgets/floatingNavigationBar.dart';

void main() {
  testWidgets('Mono Edition is light-only with dark primary action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                Text('LOCK IN', style: Theme.of(context).textTheme.titleLarge),
                Container(
                  key: const Key('mono-color'),
                  color: context.tl.primary,
                  height: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('LOCK IN'), findsOneWidget);
    expect(find.byKey(const Key('mono-color')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('User floating navbar supports all five tabs', (tester) async {
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavigationBar(
              currentIndex: 0,
              onTap: (index) => selected = index,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));

    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin floating navbar keeps six actions', (tester) async {
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavigationBar(
              currentIndex: 3,
              isAdmin: true,
              onTap: (index) => selected = index,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pengajuan'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));

    expect(selected, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shared headers and chat bubble render', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ListView(
              children: [
                TLPlayful.decoratedHeading(
                  context,
                  title: 'Find your next challenge',
                  subtitle: 'Focus. Compete. Achieve.',
                  accent: context.tl.primary,
                  icon: Icons.emoji_events_outlined,
                ),
                const TLMessageBubble(
                  own: true,
                  sender: 'Kamu',
                  message: 'Ready to compete',
                  time: '09:41',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Find your next challenge'), findsOneWidget);
    expect(find.text('Ready to compete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}