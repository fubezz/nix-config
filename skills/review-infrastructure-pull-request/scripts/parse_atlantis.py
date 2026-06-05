#!/usr/bin/env python3
"""
parse_atlantis.py — Parse Atlantis PR comments from `gh api` NDJSON output.

Usage:
  gh api repos/OWNER/REPO/issues/NUMBER/comments --paginate \
    --jq '.[] | select(.user.login | test("atlantis|github-actions"; "i")) | {id:.id,body:.body,created_at:.created_at}' \
    | python3 parse_atlantis.py [--mode plan|policy|all]

Outputs a JSON summary to stdout with:
  - plan_summaries: per-dir plan results (add/change/destroy counts)
  - destructions: resources being destroyed
  - replacements: resources being replaced (-/+)
  - policy_warns: WARN violations
  - policy_denies: DENY/FAIL violations
  - locked_dirs: dirs locked by another PR
"""

import sys
import json
import re
import argparse
from collections import defaultdict

# Strips Terragrunt STDOUT/STDERR log prefixes like:
#   09:26:09.479 STDOUT terraform1.14.4: <actual content>
TERRAGRUNT_LOG_RE = re.compile(
    r'^\d{2}:\d{2}:\d{2}\.\d+\s+(?:STDOUT|STDERR|INFO|WARN|ERROR)\s+\S+:\s*',
    re.MULTILINE
)


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--mode", choices=["plan", "policy", "all"], default="all")
    return p.parse_args()


def read_comments(stream):
    comments = []
    for line in stream:
        line = line.strip()
        if line:
            try:
                comments.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    comments.sort(key=lambda c: c.get("created_at", ""))
    return comments


def strip_log_prefixes(text):
    """Remove Terragrunt log prefixes so plan output can be parsed normally."""
    return TERRAGRUNT_LOG_RE.sub('', text)


def extract_dir_sections(body):
    """
    Split a multi-dir Atlantis comment body into per-dir sections.

    Handles two formats:
      ### 1. dir: `path` workspace: `default`     (multi-project)
      ### dir: `path` workspace: `default`         (single-project)
    """
    sections = {}
    pattern = re.compile(
        r'###\s+(?:\d+\.\s+)?dir:\s+`([^`]+)`\s+workspace:\s+`([^`]+)`'
    )
    splits = list(pattern.finditer(body))
    if not splits:
        # No section headers — the whole body is one section; caller supplies dir
        return None
    for i, m in enumerate(splits):
        d = m.group(1)
        start = m.start()
        end = splits[i + 1].start() if i + 1 < len(splits) else len(body)
        section_raw = body[start:end]
        sections[d] = strip_log_prefixes(section_raw)
    return sections


def latest_per_dir(comments, marker_re):
    """Keep only the most recent comment that covers each dir."""
    latest = {}  # dir -> comment
    for c in comments:
        dirs = re.findall(marker_re, c["body"])
        for d in dirs:
            latest[d] = c
    return latest


def extract_replacement_reason(section, resource):
    """
    Try to find the attribute that caused a replacement.
    Looks for '# forces replacement' and returns up to one attribute name before it.
    """
    # Find the resource block
    resource_escaped = re.escape(resource)
    block_match = re.search(
        rf'#\s+{resource_escaped}\s+must be replaced.*?(?=\n#\s+\w|\Z)',
        section, re.DOTALL
    )
    if not block_match:
        return "must be replaced"
    block = block_match.group(0)
    # Look for '# forces replacement' annotations
    force_matches = list(re.finditer(r'#\s+forces replacement', block))
    if not force_matches:
        return "must be replaced"
    # Walk backwards from the first forces-replacement marker to find the attribute
    before = block[:force_matches[0].start()]
    attr_match = re.search(r'(\w+)\s*=\s*[^\n]+$', before)
    if attr_match:
        return f"`{attr_match.group(1)}` forces replacement"
    return "forces replacement"


def parse_dir_section(d, section, result):
    """Parse a single dir's plan section and add findings to result."""

    # Locked by another PR
    lock_match = re.search(
        r'Plan Failed.*?locked by.*?pull #(\d+)',
        section, re.DOTALL | re.IGNORECASE
    )
    if lock_match:
        result["locked_dirs"].append({"dir": d, "locked_by_pr": lock_match.group(1)})
        return

    # Output-only (no real infra change)
    if re.search(r'apply this plan to save these new output values', section, re.IGNORECASE):
        result["output_only_dirs"].append(d)
        result["plan_summaries"].append({
            "dir": d,
            "summary": "Output values only (0 to add, 0 to change, 0 to destroy)"
        })
        return

    # No changes
    if re.search(r'No changes\. (Your infrastructure matches|Infrastructure is up-to-date)', section):
        result["no_changes_dirs"].append(d)
        result["plan_summaries"].append({"dir": d, "summary": "No changes"})
        return

    # Standard plan summary
    summary_match = re.search(
        r'Plan:\s*(\d+) to add,\s*(\d+) to change,\s*(\d+) to destroy\.', section
    )
    if summary_match:
        adds, changes, destroys = summary_match.groups()
        result["plan_summaries"].append({
            "dir": d,
            "summary": f"Plan: {adds} to add, {changes} to change, {destroys} to destroy",
            "adds": int(adds),
            "changes": int(changes),
            "destroys": int(destroys),
        })
        if int(destroys) > 0:
            for m in re.finditer(r'#\s+([\w.\[\]"/-]+)\s+will be destroyed', section):
                result["destructions"].append({"dir": d, "resource": m.group(1)})

    # Replacements — "must be replaced"
    seen_replacements = set()
    for m in re.finditer(r'#\s+([\w.\[\]"/-]+)\s+must be replaced', section):
        resource = m.group(1)
        if resource not in seen_replacements:
            seen_replacements.add(resource)
            reason = extract_replacement_reason(section, resource)
            result["replacements"].append({"dir": d, "resource": resource, "reason": reason})

    # Replacements — explicit -/+ resource lines (fallback if "must be replaced" not present)
    for m in re.finditer(r'^\s*-/\+\s+resource\s+"(\w+)"\s+"(\w+)"', section, re.MULTILINE):
        resource = f'{m.group(1)}.{m.group(2)}'
        if resource not in seen_replacements:
            seen_replacements.add(resource)
            result["replacements"].append({
                "dir": d,
                "resource": resource,
                "reason": "destroy-then-create (-/+)"
            })


def parse_plan_comments(comments):
    plan_marker = r'dir:\s*`([^`]+)`\s+workspace:\s*`default`'
    plan_comments = [c for c in comments if "Ran Plan for" in c.get("body", "")]
    latest = latest_per_dir(plan_comments, plan_marker)

    result = {
        "plan_summaries": [],
        "destructions": [],
        "replacements": [],
        "locked_dirs": [],
        "output_only_dirs": [],
        "no_changes_dirs": [],
    }

    processed_dirs = set()
    for d, c in sorted(latest.items(), key=lambda x: x[0]):
        if d in processed_dirs:
            continue
        processed_dirs.add(d)

        body = c["body"]
        sections = extract_dir_sections(body)

        if sections is not None:
            # Multi-dir comment: use only the section for this dir
            section = sections.get(d)
            if section is None:
                continue
        else:
            # Single-dir comment: strip log prefixes from entire body
            section = strip_log_prefixes(body)

        parse_dir_section(d, section, result)

    return result


def parse_policy_comments(comments):
    policy_marker = r'dir:\s*`([^`]+)`\s+workspace:\s*`default`'
    policy_comments = [c for c in comments if "Ran Policy Check" in c.get("body", "")]
    latest = latest_per_dir(policy_comments, policy_marker)

    warns = []
    denies = []

    for d, c in sorted(latest.items(), key=lambda x: x[0]):
        body = c["body"]
        for m in re.finditer(r'WARN\s*-\s*([^\n]+)', body):
            parts = [p.strip() for p in m.group(1).split(" - ", 2)]
            warns.append({
                "dir": d,
                "file": parts[0] if len(parts) > 0 else "",
                "rule": parts[1] if len(parts) > 1 else "",
                "message": parts[2] if len(parts) > 2 else m.group(1),
            })
        for m in re.finditer(r'(DENY|FAIL|ERROR)\s*-\s*([^\n]+)', body):
            parts = [p.strip() for p in m.group(2).split(" - ", 2)]
            denies.append({
                "dir": d,
                "severity": m.group(1),
                "file": parts[0] if len(parts) > 0 else "",
                "rule": parts[1] if len(parts) > 1 else "",
                "message": parts[2] if len(parts) > 2 else m.group(2),
            })

    def dedup(items):
        seen = set()
        out = []
        for item in items:
            key = (item.get("rule", ""), item.get("message", ""))
            if key not in seen:
                seen.add(key)
                out.append(item)
        return out

    return {
        "policy_warns": dedup(warns),
        "policy_warns_raw": warns,
        "policy_denies": dedup(denies),
        "policy_denies_raw": denies,
        "warn_count": len(warns),
        "deny_count": len(denies),
        "affected_dirs_warn": list(dict.fromkeys(w["dir"] for w in warns)),
        "affected_dirs_deny": list(dict.fromkeys(d["dir"] for d in denies)),
    }


def main():
    args = parse_args()
    comments = read_comments(sys.stdin)

    output = {}

    if args.mode in ("plan", "all"):
        output.update(parse_plan_comments(comments))

    if args.mode in ("policy", "all"):
        output.update(parse_policy_comments(comments))

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
