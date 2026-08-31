"""Rebuild the >50k place/activity association dataset from the bundled OSM snapshot.

The script never scrapes Google Maps. It preserves OSM source IDs/URLs and marks activity labels as
derived classifications. Specific activities such as surfing are only emitted when the place name or
description contains source evidence for that activity.
"""
from pathlib import Path
import csv, json

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "backend/src/main/resources/open-data/sri-lanka-places.json"
OUTPUT = ROOT / "backend/src/main/resources/open-data/sri-lanka-place-activities.csv"

def activities(place):
    category = place.get("category", "")
    text = f"{place.get('name','')} {place.get('description','')}".lower()
    if category == "Water Sports":
        if "surf" in text: return ["Surfing", "Water sports", "Photography"]
        if "div" in text or "snork" in text: return ["Diving or snorkelling", "Water sports", "Photography"]
        if "swim" in text or "pool" in text: return ["Swimming", "Water sports", "Recreation"]
        return ["Water sports", "Coastal recreation", "Photography"]
    mapping = {
        "Beaches": ["Beach visit", "Sunset watching", "Photography"],
        "Wildlife": ["Wildlife Safari", "Wildlife watching", "Bird watching", "Photography"],
        "Hiking": ["Hiking", "Trekking", "Scenic viewpoint", "Photography"],
        "Mountains & Peaks": ["Hiking", "Scenic viewpoint", "Photography"],
        "Adventure": ["Scenic viewpoint", "Adventure", "Photography"],
        "Temples": ["Temple visit", "Culture", "Heritage", "Photography"],
        "Culture": ["Culture", "Heritage", "Sightseeing", "Photography"],
        "History": ["History", "Heritage", "Sightseeing", "Photography"],
        "Waterfalls": ["Waterfall visit", "Nature", "Photography"],
        "Forests": ["Nature walk", "Wildlife watching", "Photography"],
        "Nature": ["Nature walk", "Wildlife watching", "Photography"],
        "Rivers": ["River visit", "Nature", "Photography"],
        "Ponds & Lakes": ["Lake visit", "Nature", "Photography"],
        "Rocks & Caves": ["Cave or rock visit", "Adventure", "Photography"],
        "Camping & Picnics": ["Camping", "Picnic", "Nature"],
        "Cycling": ["Cycling", "Adventure", "Sightseeing"],
        "Boating & Marinas": ["Boating", "Marina visit", "Photography"],
        "Gardens": ["Garden visit", "Nature walk", "Photography"],
        "Food": ["Local food", "Food experience", "Cafe or restaurant"],
        "Markets": ["Market visit", "Local shopping", "Food experience"],
        "Farms": ["Farm visit", "Rural experience", "Photography"],
        "Sports": ["Sports", "Recreation", "Local experience"],
        "Attraction": ["Sightseeing", "Local attraction", "Photography"],
    }
    return mapping.get(category, ["Sightseeing", "Photography", "Local experience"])

def main():
    places = json.loads(SOURCE.read_text(encoding="utf-8"))
    count = 0
    with OUTPUT.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["place_name","category","activity","latitude","longitude","source_reference","source_url","classification"])
        for place in places:
            for activity in activities(place):
                writer.writerow([place.get("name",""), place.get("category",""), activity,
                                  place.get("latitude",""), place.get("longitude",""),
                                  place.get("sourceReference",""), place.get("sourceUrl",""),
                                  "DERIVED_FROM_OSM_CATEGORY_AND_NAME"])
                count += 1
    print(f"{len(places):,} unique source-linked places -> {count:,} place/activity records")

if __name__ == "__main__":
    main()
