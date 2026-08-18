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

Important: this milestone intentionally identifies the generator as `RULE_BASED_BASELINE`. It is not presented as trained AI. Live Geoapify/OpenStreetMap place enrichment, Gemini itinerary refinement, saved plan editing, and the separate XGBoost cost-prediction service are later milestones.

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

Add the Geoapify/OpenStreetMap provider adapter and use real place coordinates, opening information, routes, and travel times. Then add Gemini as a constrained itinerary-refinement layer over verified place data. Cost prediction remains a separate Python service using **XGBoost only** after a usable training dataset is identified and evaluated; Random Forest is excluded.
