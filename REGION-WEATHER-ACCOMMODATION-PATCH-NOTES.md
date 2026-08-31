# Region + Weather + Accommodation Alternatives Patch

This patch is designed to be copied over the current AI Travel Planner after the existing itinerary preference/speed/transport patches.

## What changes

- Adds multi-select **travel regions** before place/activity preferences.
- Place chips are filtered by the selected travel regions.
- Activity chips are filtered by selected regions and selected place types.
- Backend candidate selection is restricted to the selected travel regions while keeping the existing nearest/best itinerary route algorithm.
- Adds a 91,373-row region/place/activity derived dataset from the existing source-linked Sri Lanka OSM place/activity data.
- Adds real forecast weather on itinerary cards using Open-Meteo with coordinates/date and a short cache.
- Adds alternative accommodation suggestions to accommodation cards.
- Replaces the user-supplied ride-hailing planning assumptions with:
  - Tuk Tuk: first 1 km LKR 200; midpoint additional km LKR 80 (range supplied: 70–90)
  - Car: first 1 km LKR 450; midpoint additional km LKR 97.5 (range supplied: 85–110)
  - Minivan: first 1 km LKR 800; midpoint additional km LKR 120 (range supplied: 110–130)
  - Van: first 1 km LKR 1500; midpoint additional km LKR 175 (range supplied: 150–200)
- The first-kilometre minimum still applies to journeys shorter than 1 km.

## Travel regions used by the UI

- Western Province
- Southern Province
- Upcountry / Central Highlands
- Cultural Triangle / North Central
- Eastern Province
- Northern Province
- North Western / Wayamba
- Sabaragamuwa / Rainforest
- Uva / South-East Wildlife

Some tourism areas intentionally overlap (for example Ella/Haputale and the south-east wildlife belt), while impossible choices such as beaches for Upcountry-only selection are not displayed.

## Install

1. Stop the Flutter app and Spring backend.
2. Extract this ZIP.
3. Copy all folders/files into `C:\Users\adilm\Projects\ai-travel-planner`.
4. Choose **Replace the files in the destination**.

## Correct startup/test order

Start XAMPP MySQL on port 3307.

Backend CMD:

```cmd
title 2 - SPRING BACKEND
cd /d "C:\Users\adilm\Projects\ai-travel-planner\backend"
set "DB_URL=jdbc:mysql://localhost:3307/ai_travel_planner?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
set "DB_USERNAME=root"
set "DB_PASSWORD="
mvn test
```

Only after `BUILD SUCCESS`:

```cmd
mvn spring-boot:run
```

Wait for `Started AiTravelPlannerApplication` and keep the backend CMD open.

Emulator CMD:

```cmd
title 1 - ANDROID EMULATOR
"%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd Pixel_7 -no-snapshot-load -gpu swiftshader_indirect
```

Flutter CMD:

```cmd
title 3 - FLUTTER APP
cd /d "C:\Users\adilm\Projects\ai-travel-planner"
flutter pub get
flutter test
```

Only after `All tests passed!`:

```cmd
flutter run -d emulator-5554
```

## Data wording for report/viva

The large region dataset contains derived **region/place/activity associations** from the existing source-linked OpenStreetMap tourism/POI snapshot. It is not 91,373 manually verified tourist attractions. Tourism-region/category rules were informed by Sri Lanka tourism sources and the runtime planner uses the same region classification rules.

Weather is fetched live from Open-Meteo; if the weather service is unavailable the itinerary remains usable and the weather line is simply omitted.
