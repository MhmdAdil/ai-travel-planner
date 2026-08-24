# Milestone 3 viva notes

## What I implemented

I replaced the small hard-coded itinerary place source with a live OpenStreetMap integration. The Spring Boot backend first geocodes the user's Sri Lankan destination using Nominatim and then retrieves named points of interest using the Overpass API. It ranks those places using the traveller's interests and activities and divides unique places into the available trip days.

The itinerary stores each live place's latitude, longitude, OpenStreetMap reference and source URL. The Flutter result screen identifies live and fallback data and lets the traveller view a live place on an OpenStreetMap map.

## Reliability and responsible API use

Public APIs may be unavailable during a demonstration, so I implemented a fallback provider using the verified Milestone 2 place catalogue. The app tells the user which provider was used. Destination results are cached for six hours, Nominatim calls are limited to one request per second, a project-specific User-Agent is supplied, and autocomplete is not used.

## How personalization works

The backend expands preferences into related search terms. For example, hiking also matches nature, peaks and viewpoints, while culture matches temples and museums. Matching places are ranked first and distance is used as a secondary ordering rule. Places are allocated without duplicates until the available live set is exhausted.

## Important limitation to explain

OpenStreetMap supplies real place identities and coordinates, but it does not reliably supply entrance fees. Therefore, visit durations, activity prices and travel times are still labelled planning estimates. The cost model is not yet XGBoost; XGBoost will be trained and evaluated in the separate cost-prediction milestone.

## Short viva answer

“In Milestone 3, I integrated Nominatim and Overpass through the Spring Boot backend to obtain real Sri Lankan destinations and points of interest. I added caching, API throttling, preference-based ranking, coordinates, map previews and an automatic fallback catalogue. I clearly separate real OSM place data from estimated costs and durations.”
