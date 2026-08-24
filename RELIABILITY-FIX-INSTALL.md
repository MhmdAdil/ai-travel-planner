# Milestone 3 reliability-fix installation

1. Stop Flutter with `q` in the Flutter Command Prompt.
2. Stop Spring Boot with `Ctrl+C` and confirm with `y` when asked.
3. Extract the corrected project ZIP.
4. Copy everything inside its `ai-travel-planner` folder into
   `C:\Users\adilm\Projects\ai-travel-planner` and replace matching files.
5. Keep XAMPP MySQL and the Android emulator running.
6. Start the backend using the normal database environment variables and
   `mvn spring-boot:run`. No `OVERPASS_URL` command is required.
7. Start Flutter with `flutter pub get`, followed by `flutter run`.
8. Log in again, open Discover, set the emulator to Colombo coordinates
   `6.9271, 79.8612`, and select 1 km.

The backend now automatically tries multiple live Overpass instances. If every
free public service is unavailable, Discover displays clearly labelled local
demonstration fallback markers instead of failing.
# Discover GPS refresh correction

This update also corrects the Discover map location refresh. The app now requests
the latest Android GPS coordinates when the radius changes or Retry is pressed,
then recenters the map on those coordinates.
