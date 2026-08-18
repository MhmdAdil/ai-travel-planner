# Project changelog

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
