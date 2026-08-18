// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Planificador de Viajes IA';

  @override
  String get navHome => 'Inicio';

  @override
  String get navDiscover => 'Descubrir';

  @override
  String get navItinerary => 'Itinerario';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Perfil';

  @override
  String get homeTitle => 'Inicio';

  @override
  String get discoverTitle => 'Descubrir';

  @override
  String get itineraryTitle => 'Itinerario';

  @override
  String get chatTitle => 'Chat';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get loginTitle => 'Bienvenido de nuevo';

  @override
  String get loginSubtitle =>
      'Inicia sesión para seguir planificando tus viajes';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerSubtitle =>
      'Regístrate para empezar a planificar tus viajes';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get noAccountPrompt => '¿No tienes una cuenta?';

  @override
  String get haveAccountPrompt => '¿Ya tienes una cuenta?';

  @override
  String get logoutButton => 'Cerrar sesión';

  @override
  String get emailValidationError => 'Introduce un correo electrónico válido';

  @override
  String get passwordValidationError =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get confirmPasswordValidationError => 'Las contraseñas no coinciden';

  @override
  String get genericAuthError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get registerSuccessMessage => 'Cuenta creada. Inicia sesión.';
}
