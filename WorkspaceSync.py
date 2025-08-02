# Gemini made this script - not me.
# This script is used to sync our module folder to the workspace.
# It was modified again to also sync the config folder to our current workspace so we can also commit those files for easy access and config history for each developer.

import time
import os
import shutil
import sys
from filecmp import cmp
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

if len(sys.argv) <= 2:
    print("Usage: python WorkspaceSync.py <workspace_directory> <dev_name>")
    sys.exit(1)

SOURCE_DIR = os.path.abspath('./Modules')
SYNC_TIMING_DIR = os.path.abspath('./Timings/' + sys.argv[2])

if not os.path.exists(SYNC_TIMING_DIR):
    os.makedirs(SYNC_TIMING_DIR)

TARGET_DIR = os.path.abspath(sys.argv[1] + "/Lycoris-Rewrite-TypeSoul-Modules")
TIMING_DIR = os.path.abspath(sys.argv[1] + "/Lycoris-Rewrite-TypeSoul-Timings")

if not os.path.exists(TARGET_DIR):
    print(f"Target directory does not exist: {TARGET_DIR}")
    sys.exit(1)

if not os.path.isdir(SOURCE_DIR):
    print(f"Source directory is not a valid directory: {SOURCE_DIR}")
    sys.exit(1)

if not os.path.exists(TIMING_DIR):
    print(f"Timing directory does not exist: {TIMING_DIR}")
    sys.exit(1)
    
if not os.path.isdir(SYNC_TIMING_DIR):
    print(f"Sync timing directory is not a valid directory: {SYNC_TIMING_DIR}")
    sys.exit(1)

def sync_directories():
    """Initial sync of SOURCE_DIR to TARGET_DIR."""
    for root, dirs, files in os.walk(SOURCE_DIR):
        for file in files:
            src_path = os.path.join(root, file)
            rel_path = os.path.relpath(src_path, SOURCE_DIR)
            dest_path = os.path.join(TARGET_DIR, rel_path)

            os.makedirs(os.path.dirname(dest_path), exist_ok=True)

            # Copy if file does not exist or contents differ
            if not os.path.exists(dest_path) or not cmp(src_path, dest_path, shallow=False):
                try:
                    shutil.copy2(src_path, dest_path)
                    print(f"Synced: {src_path} → {dest_path}")
                except Exception as e:
                    print(f"Failed to copy {src_path}: {e}")

def sync_timing_directories():
    """Initial sync of TIMING_DIR to SYNC_TIMING_DIR."""
    for root, dirs, files in os.walk(TIMING_DIR):
        for file in files:
            src_path = os.path.join(root, file)
            rel_path = os.path.relpath(src_path, TIMING_DIR)
            dest_path = os.path.join(SYNC_TIMING_DIR, rel_path)

            os.makedirs(os.path.dirname(dest_path), exist_ok=True)

            # Copy if file does not exist or contents differ
            if not os.path.exists(dest_path) or not cmp(src_path, dest_path, shallow=False):
                try:
                    shutil.copy2(src_path, dest_path)
                    print(f"Synced: {src_path} → {dest_path}")
                except Exception as e:
                    print(f"Failed to copy {src_path}: {e}")


                 

class ChangeHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if not event.is_directory:
            self.copy_file(event.src_path)

    def on_created(self, event):
        if not event.is_directory:
            self.copy_file(event.src_path)

    def copy_file(self, src_path):
        relative_path = os.path.relpath(src_path, SOURCE_DIR)
        target_path = os.path.join(TARGET_DIR, relative_path)

        os.makedirs(os.path.dirname(target_path), exist_ok=True)

        try:
            shutil.copy2(src_path, target_path)
            print(f"Copied: {src_path} → {target_path}")
        except Exception as e:
            print(f"Failed to copy {src_path}: {e}")

class TimingChangeHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if not event.is_directory:
            self.copy_timing_file(event.src_path)

    def on_created(self, event):
        if not event.is_directory:
            self.copy_timing_file(event.src_path)

    def copy_timing_file(self, src_path):
        relative_path = os.path.relpath(src_path, TIMING_DIR)
        target_path = os.path.join(SYNC_TIMING_DIR, relative_path)

        os.makedirs(os.path.dirname(target_path), exist_ok=True)

        try:
            shutil.copy2(src_path, target_path)
            print(f"Copied: {src_path} → {target_path}")
        except Exception as e:
            print(f"Failed to copy {src_path}: {e}")

def main():
    print(f"Performing initial sync from {SOURCE_DIR} to {TARGET_DIR}...")
    sync_directories()

    print(f"Performing initial sync from {TIMING_DIR} to {SYNC_TIMING_DIR}...")
    sync_timing_directories()
                    
    print(f"Watching for changes in: {SOURCE_DIR}")
    event_handler = ChangeHandler()
    observer = Observer()
    observer.schedule(event_handler, path=SOURCE_DIR, recursive=True)
    observer.start()

    print(f"Watching for changes in: {TIMING_DIR}")
    timing_event_handler = TimingChangeHandler()
    timing_observer = Observer()
    timing_observer.schedule(timing_event_handler, path=TIMING_DIR, recursive=True)
    timing_observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        timing_observer.stop()

if __name__ == "__main__":
    main()
