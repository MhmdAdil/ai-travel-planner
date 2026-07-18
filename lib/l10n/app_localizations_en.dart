// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Travel Planner';

  @override
  String get navHome => 'Home';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navItinerary => 'Itinerary';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeTitle => 'Home';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get itineraryTitle => 'Itinerary';

  @override
  String get chatTitle => 'Chat';

  @override
  String get profileTitle => 'Profile';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to keep planning your trips';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Sign up to start planning your trips';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get loginButton => 'Log in';

  @override
  String get registerButton => 'Sign up';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get logoutButton => 'Log out';

  @override
  String get emailValidationError => 'Enter a valid email address';

  @override
  String get passwordValidationError =>
      'Password must be at least 6 characters';

  @override
  String get confirmPasswordValidationError => 'Passwords do not match';

  @override
  String get genericAuthError => 'Something went wrong. Please try again.';

  @override
  String get registerSuccessMessage => 'Account created. Please log in.';
}
