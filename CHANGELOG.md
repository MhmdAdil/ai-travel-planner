# Project changelog

## Discover session and result-continuity correction

- Made nearby-place search and in-map routing public read-only endpoints while leaving private
  itinerary and account operations protected by login.
- Prevented Flutter from attaching expired login tokens to the public Discover endpoints.
- Preserved the complete nationwide Sri Lanka OSM index and every existing activity category.
- Prevented transient empty OpenStreetMap responses from being cached for six hours.
- Ensured 5 km and 10 km searches retain confirmed matching results from smaller radii.
- Kept the last successful markers visible during a temporary refresh failure; GPS changes still
  clear markers immediately so results from different cities cannot be mixed.

## Strict-radius nationwide Discover coverage

- Preserves exact 1 km, 5 km and 10 km activity matches.
- Enforces the selected radius in both the backend and Flutter client.
- Draws the selected search circle around the current GPS location.
- Never displays a marker outside the selected radius.
- Uses a bundled 14,135-place, source-linked Sri Lanka OSM index when Overpass is unavailable.
- Expands real OSM coverage for food, cafés, parks, natural features and visitor activities.
- Represents each selected activity category independently so dense food results cannot hide
  beaches, temples, parks or other requested categories.
- Shows a truthful zero result when OSM has no named matching activity inside the circle.
- Adds strict-radius, sparse-location and multi-category coverage tests.

## Discover automatic GPS-centre correction

- Continuously monitor the device GPS while Discover is open.
- Add a six-second emulator safety check for images that do not emit location-stream updates.
- Clear markers immediately when the user moves to a different city.
- Reject stale nearby responses so an older Colombo response cannot overwrite results requested
  for Nuwara Eliya, Kandy, Galle or another location.
- Display the exact coordinates currently used by Discover and mark the GPS centre in blue.
- Keep radius changes anchored to the same centre so 1 km, 5 km and 10 km remain comparable.

## Discover place-details overflow correction

- Made the place-details bottom sheet scrollable on smaller emulator screens.
- Limited the sheet to 82% of the available screen height.
- Prevented the RenderFlex bottom overflow reported from `discover_screen.dart`.

## Discover verified OSM continuity update

- Added a source-linked verified OSM snapshot for confirmed Colombo waterfront records.
- Preserve the real OSM names, identifiers, coordinates, descriptions and source URLs.
- Return verified records when all public Overpass servers time out instead of showing a false zero.
- Keep live Overpass results enabled and merge them with the verified records when available.
- Ensure 10 km results retain every matching verified result contained in 5 km.
- Added automated checks for 1 km exclusion, 5/10 km inclusion and activity filtering.
- Added an in-app notice whenever verified snapshot records are being displayed.
- Reduced the maximum public-server wait so outage recovery completes promptly.

## Reliability update — automatic Overpass failover

- Added automatic failover across three global Overpass API instances.
- Forced HTTP/1.1-compatible requests to avoid intermittent HTTP/2 EOF failures.
- Added explicit backend connection and read timeouts.
- Increased the Flutter receive timeout so backend failover can complete.
- Return a controlled temporary-unavailable response when every public instance fails.
- Added coordinate-based demonstration fallback markers when all live instances are unavailable.

## Milestone 3 — live places and data-driven itinerary planning

### Added

- Nominatim destination lookup restricted to Sri Lanka
- Overpass API retrieval of named OpenStreetMap points of interest
- Six-hour in-memory API cache and one-request-per-second Nominatim throttle
- Live/fallback place provider with graceful automatic recovery
- Interest/activity synonym matching and distance-aware ranking
- Real latitude, longitude, OSM reference and source URL persistence
- Duplicate-free day allocation and coordinate-based travel-leg estimates
- Live-place map preview and visible source labels in Flutter
- Backend integration assertions and expanded Flutter model tests

### Current limitations

- Free public OSM services can be slow or temporarily unavailable; the app then uses fallback places.
- OpenStreetMap does not reliably provide entrance fees. Activity prices are transparent planning estimates.
- Travel distance uses an adjusted straight-line estimate, not a road-routing API result.
- Live exchange rates, saved plan editing and server-side alternative replacement are not included yet.
- XGBoost cost prediction is a separate later milestone and has not been claimed here.

## Milestone 2 — trip preferences and day-by-day planning baseline

### Added

- Complete traveller preference form with arrival/departure date and time
- Inclusive trip-day calculation
- Budget level, total LKR budget, group size, activities, interests, accommodation, food, transport, pace, and notes
- Persisted trip, itinerary-day, itinerary-item, interest, activity, and alternatives schema
- Authenticated itinerary generation, list, and detail endpoints
- Timed day-by-day schedule for seven Sri Lankan destination regions
- Alternative suggestions for each scheduled place
- Accommodation, food, transport, and activity estimate breakdown
- LKR and approximate USD totals with a configurable exchange rate
- Budget feasibility result
- MariaDB driver for XAMPP compatibility
- Backend integration tests and Flutter model tests

### Current limitations

- The generator is a rule-based development baseline, not the final AI generator.
- Places and distances use a small fallback catalogue; Geoapify/OpenStreetMap enrichment comes next.
- Removing an item changes the current app view only; server-side editing and alternative selection come next.
- The displayed costs are planning estimates. XGBoost cost prediction is not yet trained or integrated.
- USD conversion uses the `LKR_PER_USD` development setting, not a live exchange-rate API.

### Planned next

1. Geoapify/OpenStreetMap place search, geocoding, routes, and travel-time adapter
2. Saved itinerary history and server-side item replacement/removal
3. Gemini refinement using verified place data and strict structured output
4. Dataset evaluation and an XGBoost-only cost-prediction service
# Milestone 3 GPS refresh correction

- Refresh the device GPS position whenever the Discover radius changes.
- Refresh the device GPS position before retrying a nearby-place request.
- Recenter and zoom the map whenever the resolved device coordinates change.
- Limit an Android GPS lookup to eight seconds and use its last known position.
- Limit the complete Flutter nearby request to fifty seconds.
- Shorten public Overpass failover time so local fallback places appear promptly.

# Discover activity filters

- Added multi-select nearby activity filters with an Apply button.
- Added Temples, Beaches, Nature & Parks, Museums & History, Food & Cafes,
  Adventure & Viewpoints, and Attractions filter groups.
- Display only markers matching the selected activity groups.
- Display a clear empty-result message when no selected activity is available.
- Corrected the Discover map's initial zoom when device GPS is already available.
- Send the selected activity groups to the backend instead of filtering only a limited mixed result set.
- Build targeted OpenStreetMap queries for temples, beaches, parks/nature, museums/history,
  food/cafes, viewpoints/hiking, and attractions.
- Cache nearby searches separately for each selected activity combination.

# Discover trustworthy place details

- Removed the local demonstration catalogue from Discover; live failures now show an availability error.
- Excluded generic attractions that contain only a name and no supporting OpenStreetMap identity details.
- Added original OpenStreetMap source links to every live place detail panel.
- Added address, opening hours, website, phone, and OSM fee information when supplied by contributors.
- Replaced repeated category-price estimates with honest Free, fee-stated, or cost-unavailable messages.
- Replaced repeated generic descriptions with tag-specific factual summaries.
- Expanded beach and nature queries to include beach resorts, recreation grounds, and protected areas.
- Increased the live-place query allowance for 10 km searches.
- Detect Overpass runtime remarks/timeouts and fail over to another server instead of displaying a false zero-result message.
- Make 10 km Discover results include every confirmed matching place already found within 5 km.
- Recalculate the actual centre-to-place distance before accepting any result into a radius.
- Expand Beaches matching to valid named beach, coast, shore, seafront and Galle Face waterfront OSM records.
- Increase live-query time allowances and build the 10 km result on a confirmed 5 km baseline.
- Query the configured public Overpass mirrors concurrently and use the first valid response, keeping the request within the mobile timeout.

# Option 1: nationwide open-data discovery

- Keep live OpenStreetMap/Overpass as the primary nationwide place source.
- Query up to 800 named matching map features for targeted activity searches.
- Race four public Overpass endpoints and prefer the most complete valid response received in the failover window.
- Supplement live results with a 14,135-place, source-linked nationwide Sri Lankan OSM index.
- Cover beaches, temples, parks/nature, museums/history and viewpoints outside Colombo, including Kandy.
- Keep one stable GPS centre when switching between 1 km, 5 km and 10 km so larger radii are true supersets.
- Preserve verified inner-radius results when a wider public Overpass request fails.
- Label curated open-data fallback records separately and link every fallback record to its public source.
- Keep fees unknown unless the source explicitly says an entry is free or paid.
- Keep place details scrollable to prevent small-screen RenderFlex overflow.
- Return offline results—or an honest empty result—rather than a server error when all public
  Overpass endpoints are temporarily unavailable.
- Add regression coverage for Food & Cafes around Chilaw (`7.5777, 79.7944`).
