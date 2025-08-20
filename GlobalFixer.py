from pathlib import Path
import json
import copy
import msgpack  # pip install msgpack

json_path = Path("Timings/Juanito/mainjuan.preprocessor.last.json")
mp_path   = Path("Timings/Juanito/mainjuan.txt")

def load_json(p: Path):
    if not p.exists() or p.stat().st_size == 0:
        return {}
    return json.loads(p.read_text(encoding="utf-8"))

def load_msgpack(p: Path):
    if not p.exists() or p.stat().st_size == 0:
        return {}
    return msgpack.unpackb(p.read_bytes(), raw=False)

last_json = load_json(json_path)
current   = load_msgpack(mp_path)

def find_timing_from_id_name(name: str, id: str):
    for idx, container in current.items():
        if idx == "version":
            continue

        for timing in container:
            cid = timing.get("_id") or timing.get("pname")
        
            if timing.get("name") == name and cid == id:
                return timing
            
    return None

def build_current_index():
    index = {}
    for group, container in current.items():
        if group == "version" or not isinstance(container, list):
            continue
        for timing in container:
            if not isinstance(timing, dict):
                continue
            cid = timing.get("_id") or timing.get("pname")
            name = timing.get("name")
            if name and cid:
                index[(group, name, cid)] = timing
    return index

curr_index = build_current_index()
matched = 0
updated_fhb = 0
added = 0

for group, container in last_json.items():
    if group == "version" or not isinstance(container, list):
        continue
    # Ensure group exists in current
    if group not in current or not isinstance(current[group], list):
        current[group] = []
    target_list = current[group]
    for timing in container:
        if not isinstance(timing, dict):
            continue
        cid = timing.get("_id") or timing.get("pname")
        name = timing.get("name")
        if not name or not cid:
            continue
        key = (group, name, cid)
        existing = curr_index.get(key)
        if existing:
            matched += 1
            if "fhb" in timing:
                existing["fhb"] = timing["fhb"]
                updated_fhb += 1
        else:
            # Add missing timing with fhb forced true (per spec)
            new_timing = copy.deepcopy(timing)
            new_timing["fhb"] = True
            target_list.append(new_timing)
            curr_index[key] = new_timing
            added += 1

# For any timing present only in current (not in last snapshot) but lacking fhb, do nothing per spec.

print(f"Timings processed: matched={matched}, fhb_updated={updated_fhb}, added_missing={added}")

# Write out new messagepack with _fixed suffix
fixed_path = mp_path.with_name(mp_path.stem + "_fixed" + mp_path.suffix)
try:
    packed = msgpack.packb(current, use_bin_type=True)  # type: ignore[assignment]
    fixed_path.write_bytes(packed)  # type: ignore[arg-type]
    print(f"Wrote fixed timings to {fixed_path}")
except Exception as e:
    print(f"Error writing fixed timings: {e}")