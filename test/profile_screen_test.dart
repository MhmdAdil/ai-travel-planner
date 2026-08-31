import 'package:ai_travel_planner_frontend/features/profile/data/profile_repository.dart';
import 'package:ai_travel_planner_frontend/features/profile/presentation/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile screen class can be constructed', () {
    const screen = ProfileScreen();
    expect(screen, isA<ProfileScreen>());
  });

  test('profile parses username and email', () {
    final profile = TravellerProfile.fromJson({
      'id': 1,
      'username': 'adil_traveller',
      'email': 'adil@example.com',
      'role': 'TRAVELLER',
    });
    expect(profile.username, 'adil_traveller');
    expect(profile.email, 'adil@example.com');
  });
}
