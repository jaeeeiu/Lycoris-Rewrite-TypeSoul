from pathlib import Path
import json
import copy
import msgpack  # pip install msgpack

mp_path   = Path("Timings/Juanito/mainjuan_fixed.txt")

def load_msgpack(p: Path):
    if not p.exists() or p.stat().st_size == 0:
        return {}
    return msgpack.unpackb(p.read_bytes(), raw=False)

current = load_msgpack(mp_path)

for container in current.values():
    if not isinstance(container, list):
        continue

    for timing in container:
        if not isinstance(timing, dict):
            continue
        
        if not timing.get("pfht"):
            continue
        
        if timing.get("phft") != 0.25:
            print("Skipping timing with non-default phft:", timing.get("name"), timing.get("_id") or timing.get("pname"))
            continue
        
        timing["phft"] = 0.15
        print("Adjusted phft for timing:", timing.get("name"), timing.get("_id") or timing.get("pname"))
        
# Write out new messagepack file
fixed_path = mp_path.with_name(mp_path.stem + mp_path.suffix)

try:
    packed = msgpack.packb(current, use_bin_type=True)  # type: ignore[assignment]
    fixed_path.write_bytes(packed)  # type: ignore[arg-type]
    print(f"Wrote fixed timings to {fixed_path}")
except Exception as e:
    print(f"Error writing fixed timings: {e}")