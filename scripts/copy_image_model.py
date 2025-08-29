#!/usr/bin/env python3
"""
Copy deck-of-cards assets from a source directory into this project's asset folders.

- Models (.glb) -> assets/cards/models/
- Images (.png, .jpg, .jpeg, .webp) -> assets/cards/images/

Filename normalization during copy:
- Suit stays the same (c, d, h, s)
- Rank conversions: "1" -> "a" (ace), "t" -> "10" (ten)
  Examples: d1.png -> da.png, dt.png -> d10.png

Usage examples (PowerShell):

  # Use defaults (source path below) and 10 threads
  python scripts/copy_image_model.py

  # Custom source directory
  python scripts/copy_image_model.py --src "C:/Users/ryosu/Downloads/deck_of_cards"

  # Dry run and custom thread count
  python scripts/copy_image_model.py -t 10 --dry-run

Defaults:
  src: C:/Users/ryosu/Downloads/deck_of_cards
  images dest: <project_root>/assets/cards/images
  models dest: <project_root>/assets/cards/models

The script will create destination folders if missing and skip copies when the
same-sized file already exists at the destination.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Tuple

# ----------------------------- Configuration ------------------------------ #
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}
MODEL_EXTS = {".glb"}

DEFAULT_SRC = Path(r"C:/Users/ryosu/Downloads/deck_of_cards")

# ------------------------------ Data Models -------------------------------- #
@dataclass(frozen=True)
class CopyPlan:
    src: Path
    dest: Path
    kind: str  # "image" | "model"

# ------------------------------ Helpers ------------------------------------ #

def is_same_file(src: Path, dest: Path) -> bool:
    """Return True if destination exists and sizes are the same.
    This is a pragmatic and fast check to skip unnecessary copies.
    """
    try:
        return dest.exists() and src.stat().st_size == dest.stat().st_size
    except OSError:
        return False


def ensure_dir(p: Path) -> None:
    p.mkdir(parents=True, exist_ok=True)

def normalize_basename(src: Path) -> str:
    """Normalize the destination file basename according to rank rules.

    - Keep suit (first char) as-is (lowercased)
    - Convert rank: 1 -> a, t -> 10, keep others

    If the pattern doesn't match expectations, return original name.
    """
    name = src.stem.lower()
    if len(name) < 2:
        return src.name.lower()
    suit = name[0]
    rank = name[1:]
    if suit not in {"c", "d", "h", "s"}:
        return src.name.lower()

    if rank == "1":
        rank_out = "a"
    elif rank in {"t", "10"}:
        rank_out = "10"
    else:
        rank_out = rank

    return f"{suit}{rank_out}{src.suffix.lower()}"


def discover_files(src_dir: Path) -> Tuple[List[Path], List[Path]]:
    """Discover image and model files under src_dir (non-recursive)."""
    images: List[Path] = []
    models: List[Path] = []
    for p in src_dir.iterdir():
        if not p.is_file():
            continue
        ext = p.suffix.lower()
        if ext in IMAGE_EXTS:
            images.append(p)
        elif ext in MODEL_EXTS:
            models.append(p)
    return images, models


def build_copy_plans(images: Iterable[Path], models: Iterable[Path], images_dest: Path, models_dest: Path) -> List[CopyPlan]:
    plans: List[CopyPlan] = []
    for p in images:
        dest_name = normalize_basename(p)
        plans.append(CopyPlan(src=p, dest=images_dest / dest_name, kind="image"))
    for p in models:
        dest_name = normalize_basename(p)
        plans.append(CopyPlan(src=p, dest=models_dest / dest_name, kind="model"))
    return plans


def copy_one(plan: CopyPlan, dry_run: bool = False) -> Tuple[CopyPlan, str]:
    dest_parent = plan.dest.parent
    ensure_dir(dest_parent)

    if is_same_file(plan.src, plan.dest):
        return plan, "skip (same size)"

    if dry_run:
        return plan, "dry-run (would copy)"

    try:
        shutil.copy2(plan.src, plan.dest)
        return plan, "copied"
    except Exception as e:  # Fail fast with explicit error
        return plan, f"ERROR: {e}"


# ------------------------------ CLI ---------------------------------------- #

def parse_args() -> argparse.Namespace:
    project_root = Path(__file__).resolve().parents[1]

    parser = argparse.ArgumentParser(description="Copy card images and models into project assets.")
    parser.add_argument("--src", type=Path, default=DEFAULT_SRC, help="Source directory containing files (default: %(default)s)")
    parser.add_argument("--project-root", type=Path, default=project_root, help="Project root (default: inferred from script location)")
    parser.add_argument("--images-dir", type=Path, default=Path("assets/cards/images"), help="Images destination path (relative to project root if not absolute)")
    parser.add_argument("--models-dir", type=Path, default=Path("assets/cards/models"), help="Models destination path (relative to project root if not absolute)")
    parser.add_argument("-t", "--threads", type=int, default=10, help="Number of concurrent copy workers (default: %(default)s)")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be copied without writing files")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    src_dir: Path = args.src
    if not src_dir.exists() or not src_dir.is_dir():
        print(f"ERROR: Source directory not found: {src_dir}")
        return 2

    project_root: Path = args.project_root if args.project_root.is_absolute() else Path.cwd() / args.project_root

    images_dest: Path = args.images_dir if args.images_dir.is_absolute() else project_root / args.images_dir
    models_dest: Path = args.models_dir if args.models_dir.is_absolute() else project_root / args.models_dir

    print(f"Source:        {src_dir}")
    print(f"Project root:  {project_root}")
    print(f"Images dest:   {images_dest}")
    print(f"Models dest:   {models_dest}")
    print(f"Threads:       {args.threads}")
    print(f"Dry run:       {args.dry_run}")

    images, models = discover_files(src_dir)
    print(f"Discovered:    {len(images)} images, {len(models)} models")

    plans = build_copy_plans(images, models, images_dest, models_dest)
    if not plans:
        print("Nothing to do.")
        return 0

    copied = skipped = errors = 0

    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.threads)) as ex:
        futures = [ex.submit(copy_one, plan, args.dry_run) for plan in plans]
        for fut in concurrent.futures.as_completed(futures):
            plan, status = fut.result()
            kind = plan.kind
            print(f"[{status:18}] {kind:5} {plan.src.name} -> {plan.dest}")
            if status.startswith("copied"):
                copied += 1
            elif status.startswith("skip"):
                skipped += 1
            elif status.startswith("dry-run"):
                # neither copied nor skipped; just informational
                pass
            else:
                errors += 1

    print("\nSummary:")
    print(f"  Copied: {copied}")
    print(f"  Skipped(same size): {skipped}")
    print(f"  Errors: {errors}")

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
