#!/usr/bin/env python3
# Ultra minimal patch for Volt - Target KeyHandler failure

from __future__ import annotations
import sys
from pathlib import Path
import re

class LuaPreprocessor:
    def __init__(self, input_path: Path, output_path: Path):
        self.input_path = input_path
        self.output_path = output_path

    def read(self) -> str:
        with self.input_path.open("r", encoding="utf-8-sig", errors="replace") as f:
            return f.read()

    def transform(self, source: str) -> str:
        print("Applying ultra-minimal Volt patch...")

        # Completely remove the KeyHandler retry loop
        source = re.sub(r'KeyHandler retry.*?attempts', '-- KeyHandler retry disabled', source, flags=re.DOTALL)
        source = re.sub(r'KeyHandler failed to initialize after 10 attempts', '-- KeyHandler patched', source)

        # Bypass the failure check
        source = re.sub(r'if not success then', 'if false then', source, flags=re.IGNORECASE)

        # Skip onInitializeError
        source = re.sub(r'onInitializeError', 'print("KeyHandler skipped - continuing")', source)

        print("Ultra-minimal patch applied.")
        return source

    def write(self, content: str) -> None:
        self.output_path.parent.mkdir(parents=True, exist_ok=True)
        with self.output_path.open("w", encoding="utf-8", newline="") as f:
            f.write(content)

    def run(self):
        source = self.read()
        result = self.transform(source)
        self.write(result)
        print(f"✅ Wrote ultra-minimal patched file: {self.output_path}")

def main():
    script_dir = Path(__file__).resolve().parent
    input_path = script_dir / "Output" / "Bundled.lua"
    output_path = script_dir / "Output" / "Preprocessed_Bundled.lua"

    if not input_path.exists():
        print("Error: Bundled.lua not found.")
        sys.exit(1)

    LuaPreprocessor(input_path, output_path).run()

if __name__ == "__main__":
    main()
