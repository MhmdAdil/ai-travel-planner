# Itinerary preference-routing patch

Replace the files in this patch using the same relative paths inside your existing `ai-travel-planner` folder.

Main changes:
- itinerary candidates are restricted to the user's selected place interests and activities;
- the planner repeatedly chooses the strongest nearby match from the last chosen stop, while giving a strong bonus to preferences not yet covered;
- food/restaurants are not selected unless Food/Food tours is selected;
- starting Current Location no longer inserts the invalid temporary dropdown value that caused the red Flutter assertion;
- late arrival starts with a nearby accommodation/check-in;
- an accommodation recommendation is added for every overnight stay;
- optional `Finish itinerary at CMB Airport` input adds the final airport transfer;
- alternative chips are clickable and replace the displayed stop details;
- itinerary navigation is now an in-app OpenStreetMap route with live device-location updates, using the project's existing route endpoint/OSRM.

Accommodation data note:
The public `Accommodation Information for Tourists` dataset linked by the user contains about 2,130 records, not 50,000 unique accommodations. The patch therefore does not create fake duplicates. A 50-record real-source offline seed is bundled for the immediate two-day submission, and `tools/normalize_accommodation_csv.py` is included so the full downloaded public CSV can be normalized later.

After replacing the files:
1. Backend: `mvn test`
2. Start backend: `mvn spring-boot:run`
3. Flutter root: `flutter pub get`
4. Flutter tests: `flutter test`
5. Run app: `flutter run -d emulator-5554`
