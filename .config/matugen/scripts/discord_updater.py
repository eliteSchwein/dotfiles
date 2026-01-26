"""
ClassUpdate - Update class names of themes (files or folders).
"""

import asyncio
import configparser
import glob
import os
import sys
from datetime import datetime

from lib.pairs import get_pairs
from lib.replacer import replacer


def _gather_files_from_args(args: list[str], default_ext: str) -> list[str]:
    files: list[str] = []

    def add_file(p: str) -> None:
        if p.lower().endswith("." + default_ext.lower()) and os.path.isfile(p):
            files.append(p)

    def add_dir(d: str) -> None:
        # Recursively gather files with the desired extension
        pattern = os.path.join(d, "**", f"*.{default_ext}")
        files.extend(glob.glob(pattern, recursive=True))

    for a in args:
        p = os.path.expanduser(a)
        if os.path.isdir(p):
            add_dir(p)
        else:
            # allow explicit file paths even if they don't match ext? (we enforce ext here)
            add_file(p)

    # De-dup while keeping order
    seen = set()
    out = []
    for f in files:
        nf = os.path.normpath(f)
        if nf not in seen:
            seen.add(nf)
            out.append(nf)
    return out


if __name__ == "__main__":
    try:
        print("==== ClassUpdate by Saltssaumure ====\n")

        # config.ini is in the same directory as this script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        config_path = os.path.join(script_dir, "config.ini")

        config = configparser.ConfigParser()
        if not config.read(config_path):
            print(f"Could not read config file: {config_path}")
            raise SystemExit(2)

        section = os.environ.get("CLASSUPDATE_PROFILE", "DEFAULT")

        theme_dir = config.get(section, "ThemeDirectory", fallback="themes")
        file_ext = config.get(section, "FileExtension", fallback="css").lstrip(".")
        use_local_diff = config.getboolean(section, "UseLocalDiff", fallback=False)
        diff_location = config.get(section, "DiffLocation", fallback=None)

        if not diff_location:
            print(f"DiffLocation missing in [{section}] (config: {config_path})")
            raise SystemExit(2)

        # If using local diff file and path is relative, resolve relative to script dir
        if use_local_diff and not os.path.isabs(diff_location):
            diff_location = os.path.join(script_dir, diff_location)

        # --- gather targets ---
        args = sys.argv[1:]

        if args:
            # User provided files and/or directories
            css_filenames = _gather_files_from_args(args, file_ext)
            if not css_filenames:
                print(f"No .{file_ext} files found in provided args.")
                print("Usage: python scripts/discord_updater.py <file.css|dir> [more files/dirs...]")
                raise SystemExit(2)
        else:
            # No args: fall back to config ThemeDirectory (relative to repo root like your old script)
            pattern = os.path.join("..", theme_dir, "**", f"*.{file_ext}")
            css_filenames = glob.glob(pattern, recursive=True)
            if not css_filenames:
                print(f"No .{file_ext} files found under {pattern}")
                raise SystemExit(2)

        print(f"Using section: [{section}]")
        print(f"File extension: .{file_ext}")
        print(f"UseLocalDiff: {use_local_diff}")
        print(f"DiffLocation: {diff_location}")
        print(f"\nFound {len(css_filenames)} .{file_ext} files.")

        start = datetime.now()

        class_pairs = list(get_pairs(use_local_diff, diff_location))
        print(f"Loaded {len(class_pairs)} class pairs")

        total_replaced = 0
        files_changed = 0

        print("\nReplacing...")
        for css_filename in css_filenames:
            count = asyncio.run(replacer(css_filename, class_pairs))
            print(f"{css_filename}: {count}")
            if count > 0:
                files_changed += 1
                total_replaced += count

        end = datetime.now() - start
        duration = int(end.total_seconds() * 1000)
        print(f"\nReplaced {total_replaced} classes in {files_changed} files. ({duration}ms)")

    except KeyboardInterrupt:
        print("\nUser cancelled.")
