# Milestone 3 setup on Windows

This milestone does not require a Google Maps key or another paid API key. Internet access is required for live OpenStreetMap place lookup. The existing fallback catalogue keeps itinerary generation usable when the public service is unavailable.

## 1. Replace the project source

Stop `flutter run` and the Spring Boot server before replacing the old project folder. XAMPP may remain open. Because disk space is limited, do not create another backup on the C drive; the previous version is already stored in GitHub.

Extract the source-only ZIP and place its inner `ai-travel-planner` folder at:

```text
C:\Users\adilm\Projects\ai-travel-planner
```

## 2. Verify the backend

Start MySQL in XAMPP. Then open Command Prompt:

```cmd
cd /d "C:\Users\adilm\Projects\ai-travel-planner\backend"
set "DB_URL=jdbc:mysql://localhost:3307/ai_travel_planner?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
set "DB_USERNAME=root"
set "DB_PASSWORD="
mvn test
```

After `BUILD SUCCESS`, start it:

```cmd
mvn spring-boot:run
```

Wait for `Tomcat started on port 8080`.

## 3. Verify Flutter

Open a second Command Prompt:

```cmd
cd /d "C:\Users\adilm\Projects\ai-travel-planner"
flutter pub get
flutter test
flutter run
```

The package update and Kotlin messages are warnings if the APK builds successfully.

## 4. Test live itinerary generation

1. Log in.
2. Open **Itinerary**.
3. Select Kandy, Galle, Ella, Colombo, Sigiriya or Nuwara Eliya.
4. Select interests and activities.
5. Generate the itinerary.
6. Look at the message below the plan title:
   - `Live places from OpenStreetMap` means the live provider worked.
   - `fallback catalogue was used` means the public provider was temporarily unavailable.
7. For a live place, press the map icon to view its real coordinates.

## 5. Test nearby discovery

The Android emulator may initially report a Google/Palo Alto test location. In the emulator's extended controls, set a Sri Lankan test coordinate, for example Colombo:

```text
Latitude: 6.9271
Longitude: 79.8612
```

Open **Discover**, allow location access, and test the 1 km, 5 km and 10 km filters. Keep requests moderate because the project uses donated public OpenStreetMap infrastructure.

## Optional offline demonstration mode

To force itinerary fallback mode before starting Spring Boot:

```cmd
set "PLACES_LIVE_ENABLED=false"
```

Close that Command Prompt later to remove the temporary setting.
