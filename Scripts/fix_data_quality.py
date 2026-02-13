#!/usr/bin/env python3
"""
One-time data quality cleanup for LeoBook CSV files.

Fixes:
  1. Empty standings_key in standings.csv (regenerate composite key)
  2. Empty home_crest_url/away_crest_url in predictions.csv (lookup from teams.csv)
  3. region_league=Unknown in predictions.csv (lookup from schedules.csv by fixture_id)

Usage:
  python Scripts/fix_data_quality.py [--dry-run]
"""

import csv
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from Data.Access.db_helpers import (
    STANDINGS_CSV, PREDICTIONS_CSV, SCHEDULES_CSV, TEAMS_CSV
)

def fix_standings_keys(dry_run: bool = False) -> int:
    """Regenerate missing standings_key values."""
    if not os.path.exists(STANDINGS_CSV):
        print("[SKIP] standings.csv not found")
        return 0

    with open(STANDINGS_CSV, 'r', encoding='utf-8', newline='') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    fixed = 0
    for row in rows:
        key = (row.get('standings_key') or '').strip()
        if not key:
            rl = row.get('region_league', '').strip()
            team = row.get('team_name', '').strip()
            if rl and team:
                row['standings_key'] = f"{rl}_{team}".replace(' ', '_').replace('-', '_').upper()
                fixed += 1

    if fixed > 0 and not dry_run:
        with open(STANDINGS_CSV, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            writer.writerows(rows)

    print(f"[standings.csv] Fixed {fixed} empty standings_key values")
    return fixed


def fix_prediction_crests(dry_run: bool = False) -> int:
    """Lookup missing crest URLs from teams.csv."""
    if not os.path.exists(PREDICTIONS_CSV) or not os.path.exists(TEAMS_CSV):
        print("[SKIP] predictions.csv or teams.csv not found")
        return 0

    # Build team crest lookup: team_id -> crest_url
    crest_lookup = {}
    with open(TEAMS_CSV, 'r', encoding='utf-8', newline='') as f:
        for row in csv.DictReader(f):
            tid = row.get('team_id', '').strip()
            crest = row.get('team_crest', '').strip()
            if tid and crest:
                crest_lookup[tid] = crest

    with open(PREDICTIONS_CSV, 'r', encoding='utf-8', newline='') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    fixed = 0
    for row in rows:
        changed = False
        home_id = row.get('home_team_id', '').strip()
        away_id = row.get('away_team_id', '').strip()
        home_crest = (row.get('home_crest_url') or '').strip()
        away_crest = (row.get('away_crest_url') or '').strip()

        if not home_crest and home_id in crest_lookup:
            row['home_crest_url'] = crest_lookup[home_id]
            changed = True
        if not away_crest and away_id in crest_lookup:
            row['away_crest_url'] = crest_lookup[away_id]
            changed = True
        if changed:
            fixed += 1

    if fixed > 0 and not dry_run:
        with open(PREDICTIONS_CSV, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            writer.writerows(rows)

    print(f"[predictions.csv] Fixed {fixed} rows with missing crest URLs")
    return fixed


def fix_prediction_region_league(dry_run: bool = False) -> int:
    """Lookup region_league from schedules.csv for predictions with Unknown."""
    if not os.path.exists(PREDICTIONS_CSV) or not os.path.exists(SCHEDULES_CSV):
        print("[SKIP] predictions.csv or schedules.csv not found")
        return 0

    # Build fixture_id -> region_league lookup from schedules
    rl_lookup = {}
    with open(SCHEDULES_CSV, 'r', encoding='utf-8', newline='') as f:
        for row in csv.DictReader(f):
            fid = row.get('fixture_id', '').strip()
            rl = row.get('region_league', '').strip()
            if fid and rl and rl != 'Unknown':
                rl_lookup[fid] = rl

    with open(PREDICTIONS_CSV, 'r', encoding='utf-8', newline='') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    fixed = 0
    for row in rows:
        current_rl = (row.get('region_league') or '').strip()
        fid = row.get('fixture_id', '').strip()
        if (not current_rl or current_rl in ('Unknown', 'N/A')) and fid in rl_lookup:
            row['region_league'] = rl_lookup[fid]
            fixed += 1

    if fixed > 0 and not dry_run:
        with open(PREDICTIONS_CSV, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            writer.writerows(rows)

    print(f"[predictions.csv] Fixed {fixed} rows with Unknown region_league")
    return fixed


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Fix data quality issues in CSV files')
    parser.add_argument('--dry-run', action='store_true', help='Show counts without writing')
    args = parser.parse_args()

    print("=" * 60)
    print("  DATA QUALITY FIX")
    if args.dry_run:
        print("  [DRY-RUN MODE]")
    print("=" * 60)

    total = 0
    total += fix_standings_keys(args.dry_run)
    total += fix_prediction_crests(args.dry_run)
    total += fix_prediction_region_league(args.dry_run)

    print(f"\n  Total fixes: {total}")
    if args.dry_run:
        print("  [DRY-RUN] No files were modified")
