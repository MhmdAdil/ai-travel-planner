# Install and run Option 1 on Windows

This update keeps live OpenStreetMap as the primary Discover source and adds a bundled nationwide
index of 14,135 source-linked OSM activity records. It supports arbitrary GPS locations throughout
Sri Lanka without depending on a small list of popular cities.

## Install the update

1. In the Command Prompt running Flutter, press lowercase `q` once. Do not press Enter.
2. In the Command Prompt running Spring Boot, press `Ctrl+C` once.
3. Keep XAMPP MySQL and the Android emulator running.
4. Extract the downloaded ZIP.
5. Open its inner `ai-travel-planner` folder.
6. Copy everything inside that folder into:

   ```text
   C:\Users\adilm\Projects\ai-travel-planner
   ```

7. Choose **Replace the files in the destination**.

## Start the backend

Open one Command Prompt and title it `2 - SPRING BACKEND` if helpful. Run each command separately:

```cmd
cd /d "C:\Users\adilm\Projects\ai-travel-planner\backend"
set "DB_URL=jdbc:mysql://localhost:3307/ai_travel_planner?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
set "DB_USERNAME=root"
set "DB_PASSWORD="
mvn test
mvn spring-boot:run
```

Keep this window open after `Started AiTravelPlannerApplication` appears.

## Start Flutter

Open a different Command Prompt and title it `3 - FLUTTER APP` if helpful:

```cmd
cd /d "C:\Users\adilm\Projects\ai-travel-planner"
flutter pub get
flutter test
flutter run -d emulator-5554
```

Keep this window open while using the app.

## Test Discover

1. Allow precise location permission in the emulator. If it was denied, open Android Settings,
   enable location permission for the app, return to Discover and tap **Retry**.
2. Set the emulator location to Colombo (`6.9271, 79.8612`) and confirm the **Searching GPS** bar
   displays approximately those coordinates.
3. Select **Beaches** and apply it.
4. Test **1 km**, **5 km**, and **10 km** without changing the emulator location.
5. The 10 km result must preserve every matching 5 km marker because all three radii use the same
   map centre.
6. Set the emulator location to Nuwara Eliya (`6.9497, 80.7891`).
7. Wait up to six seconds. Discover should clear the Colombo markers, update **Searching GPS** and
   request Nuwara Eliya places automatically.
8. Choose **Nature & Parks**. Mapped matching records from the nationwide index remain available
   even if every public Overpass endpoint is temporarily unavailable.
9. Set the emulator to Chilaw (`7.5777, 79.7944`), choose **5 km** and **Food & Cafes**. The bundled
   dataset contains named OSM records near that point, including Sri Ram Pastry and Clement's Chilaw.

Public Overpass servers can still be slow. When they are unavailable, the app uses source-linked
records from the same nationwide OSM extract and displays an open-data banner. Only places whose
calculated distance is inside the chosen radius are displayed. The backend and Flutter client both
enforce that boundary, and the map draws the selected radius around the current GPS point. When OSM
contains no named matching activity inside the circle, Discover shows a truthful zero result; it
does not import a farther place or invent a marker.
