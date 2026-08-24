# AI Travel Planner

A mobile-first travel planning system for Sri Lanka. The current codebase contains a Flutter application and a Spring Boot REST API.

## Planned product scope

- AI-generated, day-by-day itineraries from budget, duration, interests, and travel style
- Nearby activity discovery with a map and radius filters
- Travel-cost prediction with **XGBoost only** (Random Forest is excluded)
- Travel chatbot assistant
- Guide booking as the final, time-permitting feature
- Prices shown in LKR and approximate USD
- Public/free APIs and datasets preferred; manual data collection only for uncovered gaps

## Project structure

```text
.
├── android, ios, lib, test, ...  Flutter mobile application
└── backend/                      Spring Boot + MySQL REST API
```

## Milestone 1: authentication

Implemented:

- Traveller registration: `POST /api/auth/register`
- Login and signed JWT: `POST /api/auth/login`
- BCrypt password hashing
- MySQL user persistence
- Consistent validation/error responses
- Flutter token storage and authenticated route guard
- H2-backed backend integration tests

## Milestone 2: trip preferences and day-by-day baseline

Implemented:

- Complete preference form: starting point, destination region, arrival/departure dates and times, budget level and LKR amount, traveller count, interests, activities, accommodation, food, transport, pace, and notes
- Arrival and departure days included in the plan
- Authenticated `POST /api/itinerary/generate`
- Saved trip, day, schedule-item, interest, activity, and alternative-suggestion data
- Timed day-by-day result with travel duration, distance, descriptions, and alternatives
- Cost breakdown for accommodation, food, transport, and activities
- LKR totals and approximate USD conversion using configurable `LKR_PER_USD`
- Budget comparison showing whether the generated estimate is within the user's budget
- Authenticated list/detail endpoints for saved itineraries
- Backend integration tests and Flutter model tests

## Milestone 3: live OpenStreetMap places

Implemented:

- Sri Lankan destination geocoding through the public Nominatim service
- Live tourism, historic, natural-feature, cultural, food, shopping, recreation, sport, and wildlife POIs from Overpass API
- Authenticated radius- and activity-based nearby discovery endpoint: `GET /api/places/nearby`
  (`activities` is an optional comma-separated query parameter)
- Preference-aware ranking using interests and activities
- Real coordinates and OpenStreetMap element references stored with itinerary items
- In-memory six-hour caching and Nominatim request throttling
- Automatic fallback to the verified Milestone 2 catalogue when a public service is unavailable
- Nationwide Discover continuity through a bundled 23,127-place, source-linked OpenStreetMap
  index when public Overpass endpoints are unavailable; live Overpass remains the primary source
- Duplicate-free scheduling until the available place set is exhausted
- Approximate travel-leg distance and time calculated from place coordinates and transport mode
- Map preview for each live itinerary place in Flutter
- Visible live/fallback source information and OpenStreetMap attribution
- In-map road directions from the current GPS point to a selected place, using OSRM route geometry
- One-tap **Start navigation** that opens Google Maps turn-by-turn navigation for the selected coordinates
- Distinct source-backed descriptions limited to 40 words, using an OSM description or linked
  Wikipedia summary when available and a category/tag-based activity summary otherwise

Important: `OPENSTREETMAP_LIVE` means that the place identity and coordinates came from OpenStreetMap. Visit durations, travel times and activity prices are still planning estimates. This milestone is not the XGBoost cost-prediction model.

Discover does not invent entrance prices: it displays a published fee only when the linked source
explicitly marks entry as free or supplies a charge. Otherwise it states that the price was not
published by the source. Switching between 1 km,
5 km and 10 km keeps the same GPS centre, so a wider-radius result preserves matching inner-radius
places. Press Retry to obtain a fresh device location.

The place-details panel uses **Get directions** to draw the road route directly on the current map.
**Start navigation** opens the installed Google Maps application (or its supported web URL) with
turn-by-turn driving navigation to the selected latitude and longitude. Descriptions are short and
factual: an OSM description or linked Wikipedia summary is used when available; otherwise the app
summarizes the mapped category and relevant tags into a place-specific activity description. It does
not claim that swimming, surfing, hiking or another activity is safe unless the source supports it.
Google Maps descriptions, reviews and prices are not copied into the OpenStreetMap dataset.

The activity picker keeps the original Temples, Beaches, Nature & Parks, Museums & History,
Food & Cafes, Adventure & Viewpoints and Attractions groups. It also supports Waterfalls, Rivers,
Ponds & Lakes, Rocks & Caves, Mountains & Peaks, Farms, Forests, Shopping Malls, Water Parks,
Wildlife & Zoos, Gardens, Camping & Picnics, Hiking & Trails, Cycling, Surfing & Water Sports,
Boating & Marinas, Sports & Recreation, Cinemas & Theatres, Markets, Playgrounds and Hot Springs.

Discover also continuously observes GPS changes and clears results from the previous city before
requesting the new location. Late responses belonging to an old centre are discarded. Live OpenStreetMap discovery works
wherever the selected activity is mapped. The bundled nationwide OSM index covers Sri Lanka rather
than a fixed city list, so mapped records remain available during a public Overpass outage. Exact
in-radius matches are preserved. If one selected activity has no named match inside the chosen
radius, Discover reports a truthful zero result. It never adds markers from outside the selected
circle. The backend and Flutter client both enforce the calculated distance, and the map draws the
selected radius around the current GPS point. No location or distance is fabricated.

### Requirements

- Flutter SDK compatible with Dart 3.12
- JDK 21
- Maven 3.9+
- MySQL 8+ or XAMPP MariaDB

### Run MySQL and backend

MySQL can create the database automatically when the configured user has permission. Set environment variables in Android Studio/IntelliJ, PowerShell, or your terminal:

```text
DB_USERNAME=root
DB_PASSWORD=your_mysql_password
JWT_SECRET=replace-with-a-random-secret-of-at-least-32-characters
```

Then run:

```bash
cd backend
mvn spring-boot:run
```

The API starts at `http://localhost:8080`. Run backend tests with `mvn test`. For Adil's XAMPP/MariaDB port `3307` setup, follow [backend/SETUP-WINDOWS.md](backend/SETUP-WINDOWS.md).

Live place lookup is enabled by default. It can be disabled for offline demonstrations:

```text
PLACES_LIVE_ENABLED=false
```

The configurable endpoints are `NOMINATIM_URL` and `OVERPASS_URL`. `OSM_USER_AGENT` must continue to identify this application. The implementation caches geocoding results, limits public Nominatim requests to at most one per second, and does not implement prohibited autocomplete.

### Run Flutter

```bash
flutter pub get
flutter run
```

The Android emulator uses `http://10.0.2.2:8080` by default. For a physical phone, use your computer's LAN address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Replace `192.168.1.10` with your computer's actual address and ensure the phone and computer share a network.

## Authentication request examples

Register:

```json
{
  "email": "traveller@example.com",
  "password": "secret123"
}
```

Login returns a response compatible with the Flutter client:

```json
{
  "token": "signed.jwt.value",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 1,
    "email": "traveller@example.com",
    "role": "TRAVELLER"
  }
}
```

## Next milestone

Evaluate and prepare a defensible travel-cost dataset, then train and compare an **XGBoost-only** regression model using MAE, RMSE and R². Random Forest is excluded by the lecturer's requirement. The current rule-based cost estimates remain clearly labelled until that model is validated and integrated.
