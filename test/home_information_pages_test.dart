import 'package:ai_travel_planner_frontend/features/home/presentation/help_screen.dart';
import 'package:ai_travel_planner_frontend/features/home/presentation/how_to_use_screen.dart';
import 'package:ai_travel_planner_frontend/features/home/presentation/travel_rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Help screen renders key emergency contacts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HelpScreen()),
    );

    expect(find.text('Help & Safety'), findsWidgets);
    expect(find.text('Police Emergency'), findsOneWidget);
    expect(find.text('119'), findsOneWidget);
    expect(find.text('Suwasariya Ambulance'), findsOneWidget);
    expect(find.text('1990'), findsOneWidget);
  });

  testWidgets('Rules screen renders official guidance sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TravelRulesScreen()),
    );

    expect(find.text('Rules & Regulations'), findsWidgets);
    expect(find.textContaining('Visa and entry conditions'), findsOneWidget);
    expect(find.textContaining('Photography at attractions'), findsOneWidget);
  });

  testWidgets('How to use screen renders app guide', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HowToUseScreen()),
    );

    expect(find.text('How to use this app'), findsWidgets);
    expect(find.text('Start in 5 simple steps'), findsOneWidget);
    expect(find.text('Create your trip'), findsOneWidget);
  });
}
