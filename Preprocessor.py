# Yes, this too was made by AI. I'm too lazy to make it for now.
# The proper implementation will happen on Deepwoken with ArmorShield with:
# A Rust preprocessor using an actual AST, a Go server, and a proper Lua client.

from __future__ import annotations
import argparse
import sys
from pathlib import Path
from typing import Optional, Iterable, Dict, Tuple, Any
import re
import json
import hashlib
import copy

try:  # Optional dependency for MessagePack
    import msgpack  # type: ignore
except Exception:  # pragma: no cover
    msgpack = None  # Will fallback to JSON or raise a helpful error

#!/usr/bin/env python3
# Preprocessor.py
# A minimal scaffold that "parses" Bundled.lua (no-op for now) and writes Preprocessed_Bundled.lua.

class LuaPreprocessor:
    """Preprocesses Bundled.lua to optionally strip registered modules.

    Capabilities:
    - Identify all __bundle_register("path", ...) calls and their ranges.
    - Optionally remove any calls whose path matches an exclude list.
    """

    def __init__(self, input_path: Path, output_path: Path, exclude: Optional[Iterable[str]] = None, strip_texts: Optional[Iterable[str]] = None, timing_file: Optional[Path] = None):
        self.input_path = input_path
        self.output_path = output_path
        # Normalize exclude paths to use forward slashes (bundler uses /) and dots
        self.exclude = set((p.replace("\\", "/").replace('.', '/') for p in (exclude or [])))
        # Raw text patterns to strip (whitespace-insensitive)
        self.strip_texts = list(strip_texts or [])
        # Optional timing file (MessagePack preferred). Parsed lazily.
        self.timing_file = timing_file
        self._timing_data: Optional[dict[str, Any]] = None
        # Where we persist the last (unscrambled) decoded timing data for diffing across runs
        self._timing_snapshot_path: Optional[Path] = None
        if self.timing_file:
            try:
                self._timing_snapshot_path = self.timing_file.with_suffix('.preprocessor.last.json')
            except Exception:
                self._timing_snapshot_path = None
        # Snapshot for module content/name diffing
        self._modules_snapshot_path = self.output_path.parent / "modules.preprocessor.last.json"

    def read(self) -> str:
        if not self.input_path.exists():
            raise FileNotFoundError(f"Input file not found: {self.input_path}")
        # Read as UTF-8 with BOM support; typical for Lua sources in many repos
        with self.input_path.open("r", encoding="utf-8-sig", errors="replace") as f:
            return f.read()

    # --------------- Bundle register detection/removal logic ---------------
    def _find_matching_paren(self, source: str, paren_start: int) -> int:
        """Return index after the matching ')' for a '(' at paren_start.

        Lua-aware scanner: counts parentheses while ignoring chars inside strings
        (single/double quotes), long strings ([=[ ... ]=]), and comments
        (-- line, --[[ ... ]]). Returns the index just after the matching ')'.
        Raises ValueError if not found.
        """
        i = paren_start
        n = len(source)
        depth = 0
        in_sl_comment = False  # -- ...\n
        in_ml_comment = False  # --[[ ... ]]
        ml_comment_eq = 0

        in_string = False
        string_quote = ''

        in_long_string = False  # [[ ... ]]
        long_str_eq = 0

        def starts_long_bracket(idx: int) -> tuple[bool, int, int]:
            # Detect [=*[ at idx; return (True, '=', total_len) if starts, with count of '='s and token length
            if idx >= n or source[idx] != '[':
                return False, 0, 0
            j = idx + 1
            eqc = 0
            while j < n and source[j] == '=':
                eqc += 1
                j += 1
            if j < n and source[j] == '[':
                return True, eqc, (j - idx + 1)
            return False, 0, 0

        def ends_long_bracket(idx: int, eqc: int) -> tuple[bool, int]:
            # Detect ]=*] at idx; return (True, token_len) when matches
            if idx >= n or source[idx] != ']':
                return False, 0
            j = idx + 1
            k = 0
            while j < n and k < eqc and source[j] == '=':
                j += 1
                k += 1
            if k == eqc and j < n and source[j] == ']':
                return True, (j - idx + 1)
            return False, 0

        # Start scanning; include the initial '('
        while i < n:
            ch = source[i]

            # Single-line comment handling
            if in_sl_comment:
                if ch == '\n':
                    in_sl_comment = False
                i += 1
                continue

            # Multi-line comment handling
            if in_ml_comment:
                end_ok, tok_len = ends_long_bracket(i, ml_comment_eq)
                if end_ok:
                    in_ml_comment = False
                    i += tok_len
                else:
                    i += 1
                continue

            # Long string handling
            if in_long_string:
                end_ok, tok_len = ends_long_bracket(i, long_str_eq)
                if end_ok:
                    in_long_string = False
                    i += tok_len
                else:
                    i += 1
                continue

            # Quoted string handling
            if in_string:
                if ch == '\\':  # escape next char
                    i += 2
                    continue
                if ch == string_quote:
                    in_string = False
                i += 1
                continue

            # Not in any special state: check for start of comment/strings/long strings
            if ch == '-' and (i + 1) < n and source[i + 1] == '-':
                # Comment: line or block
                j = i + 2
                ok, eqc, tok_len = starts_long_bracket(j)
                if ok:
                    in_ml_comment = True
                    ml_comment_eq = eqc
                    i = j + tok_len
                else:
                    in_sl_comment = True
                    i = j
                continue

            if ch in ('"', "'"):
                in_string = True
                string_quote = ch
                i += 1
                continue

            ok, eqc, tok_len = starts_long_bracket(i)
            if ok:
                in_long_string = True
                long_str_eq = eqc
                i += tok_len
                continue

            # Count parentheses when not in strings/comments
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    return i + 1  # position after matching ')'

            i += 1

        raise ValueError("Unbalanced parentheses while scanning bundle register call")

    # -------------------------- Internal table injection --------------------------
    def _discover_lua_files(self, dir_path: Path) -> Dict[str, Path]:
        files: Dict[str, Path] = {}
        if not dir_path.exists() or not dir_path.is_dir():
            return files
        for fp in dir_path.glob("*.lua"):
            if fp.is_file():
                files[fp.stem] = fp
        return files

    def _indent_block(self, s: str, indent: str) -> str:
        if not s:
            return s
        lines = s.splitlines()
        return "\n".join((indent + line if line else indent.rstrip()) for line in lines)

    def _build_lua_table(self, entries: Dict[str, str], base_indent: str = "") -> str:
        inner_indent = base_indent + "    "
        func_indent = base_indent + "        "
        keys = list(entries.keys())
        lines: list[str] = ["{"]
        for idx, k in enumerate(keys):
            src = entries[k]
            lines.append(f'{inner_indent}["{k}"] = function()')
            if src.strip():
                lines.append(self._indent_block(src, func_indent))
            lines.append(f"{inner_indent}end{',' if idx != len(keys) - 1 else ''}")
        lines.append(base_indent + "}")
        return "\n".join(lines)

    def _inject_internal_tables(self, bundle_src: str, modules_tbl: str, globals_tbl: str) -> Tuple[str, int, int]:
        mod_pat = re.compile(r'^(?P<indent>[ \t]*)local INTERNAL_MODULES = \{\}', re.MULTILINE)
        glob_pat = re.compile(r'^(?P<indent>[ \t]*)local INTERNAL_GLOBALS = \{\}', re.MULTILINE)

        new_src = bundle_src
        replaced_modules = 0
        replaced_globals = 0

        m = mod_pat.search(new_src)
        if m:
            indent = m.group("indent")
            mods_lines = modules_tbl.splitlines()
            mods_lines = [mods_lines[0]] + [indent + line if line.strip() else indent for line in mods_lines[1:]]
            reindented_modules_tbl = "\n".join(mods_lines)
            new_src = new_src[:m.start()] + f"{indent}local INTERNAL_MODULES = {reindented_modules_tbl}" + new_src[m.end():]
            replaced_modules = 1

        g = glob_pat.search(new_src)
        if g:
            indent = g.group("indent")
            gl_lines = globals_tbl.splitlines()
            gl_lines = [gl_lines[0]] + [indent + line if line.strip() else indent for line in gl_lines[1:]]
            reindented_globals_tbl = "\n".join(gl_lines)
            new_src = new_src[:g.start()] + f"{indent}local INTERNAL_GLOBALS = {reindented_globals_tbl}" + new_src[g.end():]
            replaced_globals = 1

        return new_src, replaced_modules, replaced_globals

    def find_bundle_register_calls(self, source: str) -> list[dict]:
        """Return list of {path, start, end} for each __bundle_register call."""
        results: list[dict] = []
        # Match beginning of a register call and capture module path
        # Allow leading spaces/tabs; bundler usually emits at column 1
        regex = re.compile(r"^[ \t]*__bundle_register\(\s*\"([^\"]+)\"", re.MULTILINE)
        for m in regex.finditer(source):
            path = m.group(1)
            # Start removal from line start to clean indentation
            line_start = source.rfind('\n', 0, m.start()) + 1
            # The '(' for the call is the first '(' after '__bundle_register'
            paren_idx = source.find('(', m.start())
            if paren_idx == -1:
                continue
            try:
                call_end = self._find_matching_paren(source, paren_idx)
            except ValueError:
                # Fallback: keep original block if unmatched
                continue
            results.append({
                'path': path,
                'start': line_start,
                'end': call_end,
            })
        return results

    # -------------------------- Pipeline methods ---------------------------
    def parse(self, source: str) -> dict:
        calls = self.find_bundle_register_calls(source)
        return {
            "lines": source.count("\n") + 1 if source else 0,
            "bytes": len(source.encode("utf-8")),
            "modulesFound": len(calls),
            "modules": [c["path"] for c in calls],
        }

    # -------------------------- Timing decode & inline ---------------------------
    def _decode_timing_file(self) -> Optional[dict[str, Any]]:
        if not self.timing_file:
            return None
        p = self.timing_file
        if not p.exists() or not p.is_file():
            print(f"Warning: timing file not found: {p}")
            return None
        data = p.read_bytes()
        # Heuristic: try msgpack first if available, else JSON
        if msgpack is not None:
            try:
                obj = msgpack.unpackb(data, raw=False)
                if isinstance(obj, dict):
                    return obj  # type: ignore[return-value]
                print("Warning: decoded timing file is not a map; skipping inline.")
                return None
            except Exception as e:
                print(f"Warning: msgpack decode failed: {e}; attempting JSON fallback…")
        # Try JSON as a fallback for developer convenience
        try:
            obj = json.loads(data.decode("utf-8"))
            if isinstance(obj, dict):
                return obj  # type: ignore[return-value]
        except Exception:
            pass
        if msgpack is None:
            print("Error: msgpack (Python) is not installed. Install with: pip install msgpack; or provide a JSON timing file.")
        else:
            print("Error: failed to decode timing file as msgpack or JSON.")
            
        return None

    def _escape_lua_string(self, s: str) -> str:
        """Encode Python string as a Lua byte string literal.

        Notes:
        - For Lua 5.1 compatibility we avoid ``\\xHH`` style escapes (unsupported).
        - Keep printable ASCII (32-126) except backslash and double quote as-is.
        - Escape backslash and double quote with a preceding backslash.
        - Encode all other bytes using decimal escape sequences ``\\ddd`` (zero-padded to 3 digits) so they are unambiguous.
        This guarantees round-trip for any scrambled / binary content produced by XOR.
        """
        out_chars: list[str] = []
        for ch in s:
            o = ord(ch)
            if 32 <= o <= 126 and ch not in ('\\', '"'):
                out_chars.append(ch)
            elif ch == '"':
                out_chars.append('\\"')
            elif ch == '\\':
                out_chars.append('\\\\')
            else:
                # Decimal escape; pad to 3 to avoid ambiguity with following digits
                out_chars.append(f"\\{o:03d}")
        return '"' + ''.join(out_chars) + '"'

    def _to_lua(self, value: Any, base_indent: str = "", inline: bool = False) -> str:
        # Convert Python values (from msgpack/json) to Lua literal
        if value is None:
            return "nil"
        t = type(value)
        if t is bool:
            return "true" if value else "false"
        if t in (int, float):
            return repr(value)
        if t is str:
            return self._escape_lua_string(value)
        if isinstance(value, list):
            if not value:
                return "{}"
            if inline:
                inner = ", ".join(self._to_lua(v, base_indent, inline=True) for v in value)
                return "{" + inner + "}"
            inner_indent = base_indent + "    "
            lines = ["{"]
            for idx, v in enumerate(value):
                comma = "," if idx < len(value) - 1 else ""
                lines.append(f"{inner_indent}{self._to_lua(v, inner_indent)}{comma}")
            lines.append(base_indent + "}")
            return "\n".join(lines)
        if isinstance(value, dict):
            if not value:
                return "{}"
            # Preserve insertion order where possible; json/msgpack may already preserve
            items = list(value.items())
            if inline:
                parts = []
                for k, v in items:
                    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", str(k)):
                        parts.append(f"{k} = {self._to_lua(v, base_indent, inline=True)}")
                    else:
                        parts.append(f"[{self._escape_lua_string(str(k))}] = {self._to_lua(v, base_indent, inline=True)}")
                return "{" + ", ".join(parts) + "}"
            inner_indent = base_indent + "    "
            lines = ["{"]
            for idx, (k, v) in enumerate(items):
                key: str
                if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", str(k)):
                    key = str(k)
                else:
                    key = f"[{self._escape_lua_string(str(k))}]"
                comma = "," if idx < len(items) - 1 else ""
                lines.append(f"{inner_indent}{key} = {self._to_lua(v, inner_indent)}{comma}")
            lines.append(base_indent + "}")
            return "\n".join(lines)
        # Fallback to string
        return self._escape_lua_string(str(value))

    def _inline_internal_load(self, src: str, var_name: str, array_values: list[Any]) -> tuple[str, int]:
        """Inline var_name:load({}) with a key/value table keyed by each entry's _id.

        Example produced structure:
            var_name:load({
                ["someId"] = { ... },
                ["otherId"] = { ... },
            })
        Falls back to synthetic keys if _id missing.
        """
        pattern = re.compile(rf"^(?P<indent>[ \t]*){re.escape(var_name)}:load\s*\(\s*\{{\s*\}}\s*\)", re.MULTILINE)
        count = 0

        def build_kv_table(indent: str) -> str:
            inner_indent = indent + "    "
            lines: list[str] = ["{"]
            total = len(array_values)
            for idx, entry in enumerate(array_values):
                if not isinstance(entry, dict):
                    key = f"idx_{idx+1}"
                else:
                    key = entry.get("_id") or f"idx_{idx+1}"
                key_lua = self._escape_lua_string(str(key))
                # Generate Lua for entry with deeper indent
                entry_lua = self._to_lua(entry, base_indent=inner_indent + "    ")
                entry_lines = entry_lua.splitlines()
                if not entry_lines:
                    entry_lines = ["{}"]
                # First line with key
                lines.append(f"{inner_indent}[{key_lua}] = {entry_lines[0]}")
                # Middle lines (if any)
                for mid in entry_lines[1:-1]:
                    lines.append(f"{inner_indent}{mid}")
                # Last line gets comma if not last entry
                if len(entry_lines) > 1:
                    last_line = entry_lines[-1]
                else:
                    last_line = entry_lines[0]  # single-line already handled
                if idx < total - 1:
                    last_line = last_line + ","
                lines[-1] = lines[-1] if len(entry_lines) == 1 else lines[-1]  # keep previous lines
                if len(entry_lines) > 1:
                    # Replace last appended line (the previous last line without comma) with itself (no-op), then append closing with comma
                    lines.append(f"{inner_indent}{last_line}")
                else:
                    # Adjust single-line entry to include comma if needed
                    if idx < total - 1:
                        lines[-1] = lines[-1] + ","
            lines.append(indent + "}")
            return "\n".join(lines)

        def repl(m: re.Match) -> str:
            nonlocal count
            indent = m.group("indent")
            table_str = build_kv_table(indent)
            count += 1
            return f"{indent}{var_name}:load(\n{table_str}\n{indent})"

        new_src, n = pattern.subn(repl, src)
        return new_src, n

    def scramble_str(self, s: str) -> str:
        encrypted = ''.join(chr(ord(char) ^ 42) for char in s)
        return encrypted

    def scramble_num(self, n):
        return ((n + 5) / 12) - 69

    def scramble_hitbox(self, hitbox: dict[str, Any]) -> dict[str, Any]:
        return {
            "X": self.scramble_num(hitbox.get("X")),
            "Y": self.scramble_num(hitbox.get("Y")),
            "Z": self.scramble_num(hitbox.get("Z")),
        }
    
    # -------------------------- Macro Expansion --------------------------
    def _expand_macros(self, src: str) -> str:
        """Inline-expand PP_SCRAMBLE_NUM(expr) and PP_SCRAMBLE_STR(expr).

        Uses a simple token scan (not regex) so nested parentheses in the
        expression are handled by the existing balanced paren finder.
        """
        def expand_one(name: str, builder) -> str:
            token = name + "("
            out: list[str] = []
            i = 0
            tlen = len(token)
            while True:
                j = src.find(token, i)
                if j == -1:
                    out.append(src[i:])
                    break
                # ensure not part of a longer identifier
                if j > 0 and (src[j-1].isalnum() or src[j-1] == '_'):
                    out.append(src[i:j+1])
                    i = j + 1
                    continue
                paren_idx = j + len(name)  # '(' position
                try:
                    end_idx = self._find_matching_paren(src, paren_idx)
                except Exception:
                    out.append(src[i:j + tlen])
                    i = j + tlen
                    continue
                inner = src[j + tlen:end_idx - 1]
                expr = inner.strip()
                repl = builder(expr)
                out.append(src[i:j])
                # Logging: line number, macro type, original expression (trim if huge)
                line_no = src.count('\n', 0, j) + 1
                display_expr = expr if len(expr) <= 120 else expr[:117] + '...'
                macro_type = 'NUM' if name.endswith('NUM') else ('STR' if name.endswith('STR') else name)
                print(f"Inlined macro {macro_type} at line {line_no}: {display_expr}")
                out.append(repl)
                i = end_idx
            return ''.join(out)

        def build_num(expr: str) -> str:
            return f"(((({expr}) + 69) * 12) - 5)"

        def build_re_num(expr: str) -> str:
            return f"(((({expr}) + 5) / 12) - 69)"

        def build_str(expr: str) -> str:
            return (
                "(function(_s)local _r={} for _i=1,#_s do "
                "_r[_i]=string.char(bit32.bxor(string.byte(_s,_i),42)) end "
                "return table.concat(_r) end)(" + expr + ")"
            )

        src = expand_one("PP_SCRAMBLE_NUM", build_num)
        src = expand_one("PP_SCRAMBLE_STR", build_str)
        src = expand_one("PP_SCRAMBLE_RE_NUM", build_re_num)
        return src

    
    def _inline_timings(self, src: str) -> tuple[str, int]:
        data = self._timing_data or self._decode_timing_file()
        if not data:
            return src, 0
        # Keep original (unscrambled) deep copy for snapshot & diff BEFORE we mutate in-place
        original_data = copy.deepcopy(data)
        self._timing_data = data

        # Load previous snapshot (also expected unscrambled) and compute diff summary
        prev_snapshot: Optional[dict[str, Any]] = None
        if getattr(self, '_timing_snapshot_path', None) and self._timing_snapshot_path and self._timing_snapshot_path.exists():
            try:
                prev_snapshot = json.loads(self._timing_snapshot_path.read_text(encoding='utf-8'))
            except Exception as e:
                print(f"Warning: failed to read previous timing snapshot: {e}")

        if prev_snapshot:
            def index_by_id(arr: Any) -> Dict[str, Any]:
                out: Dict[str, Any] = {}
                if isinstance(arr, list):
                    for idx, item in enumerate(arr):
                        if isinstance(item, dict):
                            k = item.get('_id') or f'__idx_{idx}'
                            out[str(k)] = item
                return out

            containers = ['animation', 'part', 'sound']
            added_total = removed_total = modified_total = 0
            per_container_msgs: list[str] = []
            detail_lines: list[str] = []
            detail_cap = 40  # limit noisy output
            def _deep_equal(a: Any, b: Any) -> bool:
                if a is b:
                    return True
                if type(a) is not type(b):
                    return False
                if isinstance(a, dict):
                    if set(a.keys()) != set(b.keys()):
                        return False
                    for k in a.keys():
                        if not _deep_equal(a[k], b[k]):
                            return False
                    return True
                if isinstance(a, list):
                    if len(a) != len(b):
                        return False
                    for ia, ib in zip(a, b):
                        if not _deep_equal(ia, ib):
                            return False
                    return True
                return a == b

            for key in containers:
                prev_map = index_by_id(prev_snapshot.get(key)) if isinstance(prev_snapshot, dict) else {}
                curr_map = index_by_id(original_data.get(key)) if isinstance(original_data, dict) else {}
                prev_ids = set(prev_map.keys())
                curr_ids = set(curr_map.keys())
                added = sorted(curr_ids - prev_ids)
                removed = sorted(prev_ids - curr_ids)
                common = prev_ids & curr_ids
                modified_ids: list[str] = []
                for cid in common:
                    p = prev_map[cid]; c = curr_map[cid]
                    if not _deep_equal(p, c):
                        modified_ids.append(cid)
                if added or removed or modified_ids:
                    added_total += len(added); removed_total += len(removed); modified_total += len(modified_ids)
                    per_container_msgs.append(f"{key}: +{len(added)}/-{len(removed)}/~{len(modified_ids)}")
                    # Emit limited detail
                    for cid in added:
                        if len(detail_lines) < detail_cap:
                            detail_lines.append(f"  [+] {key}:{cid}")
                    for cid in removed:
                        if len(detail_lines) < detail_cap:
                            detail_lines.append(f"  [-] {key}:{cid}")
                    for cid in modified_ids:
                        if len(detail_lines) < detail_cap:
                            detail_lines.append(f"  [~] {key}:{cid}")
            if added_total or removed_total or modified_total:
                summary = ', '.join(per_container_msgs) if per_container_msgs else 'no container changes'
                print(f"Timing diff vs previous snapshot: +{added_total}/-{removed_total}/~{modified_total} ({summary})")
                if detail_lines:
                    if len(detail_lines) == detail_cap:
                        detail_lines.append("  ... (truncated)")
                    for ln in detail_lines:
                        print(ln)
            else:
                print("Timing diff vs previous snapshot: no changes detected.")

        # Persist new snapshot (unscrambled original)
        if getattr(self, '_timing_snapshot_path', None) and self._timing_snapshot_path:
            try:
                self._timing_snapshot_path.write_text(json.dumps(original_data, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
            except Exception as e:
                print(f"Warning: failed to write timing snapshot: {e}")
            
        replaced = 0
        # Expect keys: animation, part, sound
        arrays = {
            "internalAnimationContainer": data.get("animation") or [],
            "internalPartContainer": data.get("part") or [],
            "internalSoundContainer": data.get("sound") or [],
        }
        stats = {
            "internalAnimationContainer": {"timings": 0, "actions": 0},
            "internalPartContainer": {"timings": 0, "actions": 0},
            "internalSoundContainer": {"timings": 0, "actions": 0},
        }
        out = src
        for var, arr in arrays.items():
            if not isinstance(arr, list):
                continue
        
            for i, timing in enumerate(arr):
                # Scramble important properties
                if timing.get("_id"):
                    timing["_id"] = self.scramble_str(timing["_id"])
                
                timing["smod"] = self.scramble_str(timing["smod"])
                timing["name"] = self.scramble_str(timing["name"])
                timing["imxd"] = self.scramble_num(timing["imxd"])
                timing["imdd"] = self.scramble_num(timing["imdd"])
                
                if timing.get("rpd"):
                    timing["rpd"] = self.scramble_num(timing["rpd"])
                    timing["rsd"] = self.scramble_num(timing["rsd"])

                timing["hitbox"] = self.scramble_hitbox(timing["hitbox"])
                timing["STOP_TRYING_TO_DUMP_TIMINGS_LOL"] = "You can't unless you reverse Luraph or dynamically dump them <3"
            
                # Scramble actions
                action_list = timing.get("actions") or []
                for action in action_list:
                    action["_type"] = self.scramble_str(action["_type"])
                    action["name"] = self.scramble_str(action["name"])
                    action["when"] = self.scramble_num(action["when"])
                    action["hitbox"] = self.scramble_hitbox(action["hitbox"])

                # Update stats
                stats[var]["timings"] += 1
                stats[var]["actions"] += len(action_list)

            out, n = self._inline_internal_load(out, var, arr)
            replaced += n
            
        if replaced:
            # Build concise summary
            def fmt(varname: str, label: str) -> str:
                t = stats[varname]["timings"]
                a = stats[varname]["actions"]
                return f"{label}={t}t/{a}a"
            summary = ", ".join(
                [
                    fmt("internalAnimationContainer", "anim"),
                    fmt("internalPartContainer", "part"),
                    fmt("internalSoundContainer", "sound"),
                ]
            )
            total_t = sum(v["timings"] for v in stats.values())
            total_a = sum(v["actions"] for v in stats.values())
            print(f"Inlined timing data into {replaced} container load call(s).")
            print(f"Scrambled {total_t} timings / {total_a} actions ({summary}).")
        
        return out, replaced

    def transform(self, source: str, ast: dict) -> str:
        """Main transformation pipeline."""
        # 0) Macro expansion
        source = self._expand_macros(source)

        def remove_register_blocks(src: str) -> tuple[str, int]:
            calls = self.find_bundle_register_calls(src)
            if not calls:
                return src, 0
            removed = 0
            out: list[str] = []
            last = 0
            for call in calls:
                if call['path'] in self.exclude:
                    out.append(src[last:call['start']])
                    last = call['end']
                    removed += 1
            out.append(src[last:])
            return ''.join(out), removed

        def remove_require_lines(src: str) -> tuple[str, int, int]:
            req_re = re.compile(r"^[ \t]*(?:local[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]*=[ \t]*)?require\([ \t]*(['\"])([^'\"]+)\1[ \t]*\)[ \t]*;?[ \t]*(?:--.*)?$", re.MULTILINE)
            lines = src.splitlines(keepends=True)
            to_remove = set()
            removed_requires = 0
            removed_annotations = 0
            offsets: list[int] = []
            pos = 0
            for ln in lines:
                offsets.append(pos)
                pos += len(ln)

            def find_line_index(p: int) -> int:
                lo, hi = 0, len(offsets) - 1
                while lo <= hi:
                    mid = (lo + hi) // 2
                    if offsets[mid] <= p < offsets[mid] + len(lines[mid]):
                        return mid
                    if p < offsets[mid]:
                        hi = mid - 1
                    else:
                        lo = mid + 1
                return max(0, min(len(lines) - 1, lo))

            for m in req_re.finditer(src):
                path = m.group(2)
                path_norm = path.replace('\\', '/').replace('.', '/')
                if path_norm not in self.exclude:
                    continue
                line_idx = find_line_index(m.start())
                to_remove.add(line_idx)
                removed_requires += 1
                prev_idx = line_idx - 1
                while prev_idx >= 0 and lines[prev_idx].strip() == '':
                    prev_idx -= 1
                if prev_idx >= 0:
                    ann = lines[prev_idx].lstrip()
                    if ann.startswith('---@module') or ann.startswith('---@modules'):
                        parts = ann.split(maxsplit=1)
                        modname = parts[1].strip() if len(parts) > 1 else ''
                        modname = modname.replace('.', '/').strip()
                        if modname == path_norm or modname.endswith('/' + path_norm.split('/')[-1]) or modname.endswith(path_norm):
                            to_remove.add(prev_idx)
                            removed_annotations += 1

            if not to_remove:
                return src, 0, 0
            new_lines = [ln for idx, ln in enumerate(lines) if idx not in to_remove]
            return ''.join(new_lines), removed_requires, removed_annotations

        # 1) Remove requires / annotations
        src1, removed_reqs, removed_anns = remove_require_lines(source)
        # 2) Remove bundle register blocks
        src2, removed_regs = remove_register_blocks(src1)
        # 3) Strip arbitrary text patterns
        removed_text_total = 0
        if self.strip_texts:
            for patt in self.strip_texts:
                rx = re.compile(r"^[ \t]*.*" + re.escape(patt) + r".*?$", re.MULTILINE)
                src2, n = rx.subn("", src2)
                if n:
                    print(f"Removed {n} occurrence(s) of text pattern (ws-insensitive): {patt}")
                removed_text_total += n
        # 4) Inject internal tables
        root_dir = self.input_path.parent.parent if self.input_path.parent.name.lower() == 'output' else self.input_path.parent
        modules_dir = root_dir / 'Modules'
        globals_dir = modules_dir / 'Globals'
        mod_files = self._discover_lua_files(modules_dir)
        glob_files = self._discover_lua_files(globals_dir)
        mod_entries: Dict[str, str] = {k: (modules_dir / f"{k}.lua").read_text(encoding='utf-8-sig', errors='replace') for k in sorted(mod_files.keys())}
        glob_entries: Dict[str, str] = {k: (globals_dir / f"{k}.lua").read_text(encoding='utf-8-sig', errors='replace') for k in sorted(glob_files.keys())}
        modules_tbl = self._build_lua_table(mod_entries, base_indent='')
        globals_tbl = self._build_lua_table(glob_entries, base_indent='')
        # Module diffing (names + content stripped of whitespace)
        try:
            prev_mod_meta: dict[str, Any] = {}
            if self._modules_snapshot_path.exists():
                try:
                    prev_mod_meta = json.loads(self._modules_snapshot_path.read_text(encoding='utf-8')) or {}
                except Exception as e:
                    print(f"Warning: failed reading previous module snapshot: {e}")
            def norm(s: str) -> str:
                return ''.join(ch for ch in s if not ch.isspace())
            def stable_hash(text: str) -> str:
                return hashlib.sha256(text.encode('utf-8', 'replace')).hexdigest()
            curr_meta = {k: {"h": stable_hash(norm(v)), "len": len(v)} for k, v in mod_entries.items()}
            if prev_mod_meta:
                prev_names = set(prev_mod_meta.keys())
                curr_names = set(curr_meta.keys())
                added = sorted(curr_names - prev_names)
                removed = sorted(prev_names - curr_names)
                common = prev_names & curr_names
                changed = [n for n in common if prev_mod_meta.get(n, {}).get("h") != curr_meta.get(n, {}).get("h")]
                if added or removed or changed:
                    print(f"Module diff: +{len(added)}/-{len(removed)}/~{len(changed)} (added/removed/changed)")
                    detail_cap = 40
                    details: list[str] = []
                    for n in added:
                        if len(details) < detail_cap: details.append(f"  [+] {n}")
                    for n in removed:
                        if len(details) < detail_cap: details.append(f"  [-] {n}")
                    for n in changed:
                        if len(details) < detail_cap: details.append(f"  [~] {n}")
                    if len(details) == detail_cap: details.append("  ... (truncated)")
                    for ln in details:
                        print(ln)
                else:
                    print("Module diff: no changes detected.")
            else:
                print("Module diff: initial snapshot created.")
            try:
                self._modules_snapshot_path.write_text(json.dumps(curr_meta, separators=(',', ':'), ensure_ascii=False), encoding='utf-8')
            except Exception as e:
                print(f"Warning: failed writing module snapshot: {e}")
        except Exception as e:
            print(f"Warning: module diffing failed: {e}")
        src2, rmods, rglobs = self._inject_internal_tables(src2, modules_tbl, globals_tbl)
        # 5) Inline timings
        src2, inlined = self._inline_timings(src2)

        if removed_regs:
            print(f"Removed {removed_regs} bundle register block(s) matching excludes.")
        if removed_reqs or removed_anns:
            print(f"Removed {removed_reqs} require line(s) and {removed_anns} annotation line(s) matching excludes.")
        if removed_text_total:
            print(f"Removed {removed_text_total} text occurrence(s) across {len(self.strip_texts)} pattern(s).")
        print(f"Discovered {len(mod_entries)} internal module(s), {len(glob_entries)} internal global(s).")
        if rmods or rglobs:
            print(f"Replaced INTERNAL_MODULES: {bool(rmods)}, INTERNAL_GLOBALS: {bool(rglobs)}")
        return src2

    def write(self, content: str) -> None:
        self.output_path.parent.mkdir(parents=True, exist_ok=True)
        with self.output_path.open("w", encoding="utf-8", newline="") as f:
            f.write(content)

    def run(self) -> None:
        source = self.read()
        meta = self.parse(source)
        # Log discovered modules succinctly
        mods = meta.get("modules", [])
        print(f"Discovered {len(mods)} __bundle_register call(s).")
        if mods:
            # Avoid overly verbose output; show the first few
            preview = ', '.join(mods[:10]) + (" ..." if len(mods) > 10 else "")
            print(f"First modules: {preview}")
        result = self.transform(source, meta)
        self.write(result)


def resolve_paths(in_arg: Optional[str], out_arg: Optional[str]) -> tuple[Path, Path]:
    script_dir = Path(__file__).resolve().parent
    input_path = Path(in_arg).resolve() if in_arg else (script_dir / "Output/Bundled.lua").resolve()
    if out_arg:
        output_path = Path(out_arg).resolve()
    else:
        # Default output: same directory as input
        output_path = input_path.parent / "Preprocessed_Bundled.lua"
    return input_path, output_path


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Parse and optionally filter Bundled.lua module registrations, then emit Preprocessed_Bundled.lua."
    )
    parser.add_argument(
        "-i", "--input",
        help="Path to Bundled.lua (default: Output/Bundled.lua next to this script).",
        default=None,
    )
    parser.add_argument(
        "-o", "--output",
        help='Path to output file (default: "Output/Preprocessed_Bundled.lua" next to input).',
        default=None,
    )
    parser.add_argument(
        "-x", "--exclude",
        action="append",
        default=[
            "Menu/Objects/AnimationBuilderSection", 
            "Menu/Objects/BuilderSection", 
            "Menu/BuilderTab", 
            "Menu/Objects/PartBuilderSection", 
            "Menu/Objects/SoundBuilderSection",
        ],
        help="Module path to exclude from bundle (repeatable). Example: -x Menu/Objects/AnimationBuilderSection",
    )
    parser.add_argument(
        "-S", "--strip-text",
        action="append",
        default=["BuilderTab.init(window)"],
        help="Arbitrary text to remove (whitespace-insensitive). Repeatable. Example: -S 'BuilderTab.init(window)'",
    )
    parser.add_argument(
        "-t", "--timing-file",
        help="Path to a timing save file (MessagePack preferred). Will inline into internal container loads.",
        default=None,
    )
    args = parser.parse_args(argv)

    in_path, out_path = resolve_paths(args.input, args.output)
    try:
        LuaPreprocessor(in_path, out_path, exclude=args.exclude, strip_texts=args.strip_text, timing_file=Path(args.timing_file).resolve() if args.timing_file else None).run()
        print(f"Wrote: {out_path}")
        return 0
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))