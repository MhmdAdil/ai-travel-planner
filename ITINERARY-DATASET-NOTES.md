# Nationwide itinerary dataset

This build changes itinerary generation from a single-region fallback list to a nationwide recommendation flow.

## Bundled data

- `backend/src/main/resources/open-data/sri-lanka-places.json`
  - 23,127 unique source-linked OpenStreetMap POIs already present in the project.
  - Every entry retains its OSM source reference and source URL.
- `backend/src/main/resources/open-data/sri-lanka-place-activities.csv`
  - More than 50,000 place/activity association records derived from those source-linked POIs.
  - Activity labels are marked `DERIVED_FROM_OSM_CATEGORY_AND_NAME` and are not presented as Google Maps data.
  - Specific labels such as `Surfing`, `Swimming`, and `Diving or snorkelling` are only derived when the place name/description contains corresponding evidence.

The CSV can be rebuilt with:

```cmd
python tools\build_place_activity_dataset.py
```

## Itinerary logic

`NationwidePlaceCatalog` groups the OSM POIs into practical Sri Lankan travel regions using geographic anchors, maps place categories to activities, and scores matches against user interests and requested activities.

`ItineraryGenerator` then:

1. reads the user's current coordinates when available;
2. scores relevant places nationwide rather than only inside the selected destination region;
3. chooses a multi-day regional route using preference quality plus distance penalties;
4. chooses different POIs for each day and avoids duplicate OSM source IDs;
5. accounts for inter-stop travel time;
6. applies budget-level activity, accommodation, food, and transport planning estimates;
7. keeps OSM source links on itinerary items for traceability.

## Important data-quality note

The app does not scrape or copy Google Maps. The bundled POI snapshot is OpenStreetMap-derived. Costs in the itinerary are planning estimates unless a source explicitly publishes a fee. Official railway/bus fare ingestion and accommodation-price training data should remain a separate cost-prediction milestone so estimated values are not mislabeled as official fares.
