"""Rebuild sri-lanka-transport-options.csv from sri-lanka-places.json.

Rows are destination/mode planning profiles, not a claim that every row is a live timetable.
Official rail corridors and NTC fare sources should be rechecked before submission.
Ride-hailing rates use the project owner's supplied planning assumptions.
"""
import json, math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLACES = ROOT / "backend/src/main/resources/open-data/sri-lanka-places.json"
OUT = ROOT / "backend/src/main/resources/open-data/sri-lanka-transport-options.csv"
REGIONS = [
    ("Negombo / Katunayake", 7.2083, 79.8358), ("Colombo", 6.9271, 79.8612),
    ("Bentota", 6.4210, 80.0030), ("Galle / Unawatuna", 6.0329, 80.2168),
    ("Mirissa / Weligama", 5.9483, 80.4716), ("Yala / Tissamaharama", 6.2800, 81.2860),
    ("Udawalawe", 6.4388, 80.8882), ("Ella", 6.8667, 81.0466),
    ("Nuwara Eliya", 6.9497, 80.7891), ("Kandy", 7.2906, 80.6337),
    ("Sigiriya / Dambulla", 7.9570, 80.7603), ("Anuradhapura", 8.3114, 80.4037),
    ("Polonnaruwa", 7.9403, 81.0188), ("Trincomalee", 8.5874, 81.2152),
    ("Arugam Bay", 6.8404, 81.8368), ("Jaffna", 9.6615, 80.0255),
    ("Kalpitiya", 8.2330, 79.7660), ("Kitulgala", 6.9896, 80.4173),
    ("Haputale", 6.7657, 80.9526), ("Ratnapura", 6.6828, 80.3992),
]

def distance(a,b,c,d):
    r=6371.0088; p1=math.radians(a); p2=math.radians(c)
    dp=math.radians(c-a); dl=math.radians(d-b)
    x=math.sin(dp/2)**2+math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return r*2*math.atan2(math.sqrt(x),math.sqrt(1-x))

def nearest(lat, lon):
    return min(REGIONS, key=lambda r: distance(lat, lon, r[1], r[2]))[0]

def rail_service(region):
    r=region.lower()
    if any(x in r for x in ("kandy","nuwara","haputale","ella")): return "Main Line (Udarata Menike / Podi Menike where scheduled)"
    if any(x in r for x in ("galle","mirissa","weligama","bentota","colombo")): return "Coast Line service where scheduled"
    if any(x in r for x in ("negombo","katunayake","kalpitiya")): return "Puttalam Line service where scheduled"
    if any(x in r for x in ("anuradhapura","jaffna")): return "Northern Line service where scheduled"
    if "trincomalee" in r: return "Trincomalee Line service where scheduled"
    if "polonnaruwa" in r: return "Batticaloa Line service where scheduled"
    return None

profiles = [
    ("Bus","Public bus","Intercity / SLTB / private bus",45,40,6.5,True,"NTC_FARE_POLICY"),
    ("Tuk Tuk","Tuk Tuk","PickMe / Uber-type ride",3,250,90,False,"USER_PLANNING_ASSUMPTION"),
    ("Car","Car","PickMe / Uber-type ride",4,450,125,False,"USER_PLANNING_ASSUMPTION"),
    ("Minivan","Minivan","PickMe / Uber-type ride",7,800,135,False,"USER_PLANNING_ASSUMPTION"),
    ("Van","Van","PickMe / Uber-type ride",15,1500,225,False,"USER_PLANNING_ASSUMPTION"),
]
places=json.loads(PLACES.read_text(encoding="utf-8"))
with OUT.open("w",encoding="utf-8",newline="") as f:
    f.write("sourceReference\tregion\ttype\tvehicleModel\tserviceName\tcapacity\tminimumFareLkr\tperKmLkr\tperPassenger\tsource\tavailabilityBasis\n")
    rows=0
    for p in places:
        ref=p.get("sourceReference") or f"{p['name']}@{p['latitude']},{p['longitude']}"
        region=nearest(p["latitude"],p["longitude"])
        for row in profiles:
            typ,model,service,cap,minf,pkm,per_passenger,source=row
            f.write("\t".join(map(str,[ref,region,typ,model,service,cap,minf,pkm,str(per_passenger).lower(),source,"MODELED_FOR_DESTINATION"]))+"\n")
            rows+=1
        rail=rail_service(region)
        if rail:
            f.write("\t".join(map(str,[ref,region,"Train","Train",rail,500,50,4,"true","SRI_LANKA_RAILWAYS","CORRIDOR_MATCH_CONFIRM_SCHEDULE"]))+"\n")
            rows+=1
print(f"Wrote {rows:,} transport option records to {OUT}")
