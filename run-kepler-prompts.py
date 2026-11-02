#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""
Kepler OS Immutable - Automated ASD-STE100 Prompt Runner.
Parses modules 01 through 08 in numerical order, routes each prompt block
to Gemini 3.8 Flash (LOW, MEDIUM, or HIGH), and writes generated files.
"""

import argparse
import json
import os
import re
import stat
import sys
from pathlib import Path

PROMPT_HEADER_RE = re.compile(
    r"PROMPT\s+(\d+\.\d+)\s*-\s*([^\(\n]+)\(Target:\s*Gemini\s+3\.8\s+Flash\s*\[([^\]]+)\]\)",
    re.IGNORECASE,
)
PROMPT_BLOCK_RE = re.compile(
    r"\[PROMPT START\]\s*(.*?)\s*\[PROMPT END\]",
    re.DOTALL,
)
FILE_BLOCK_RE = re.compile(
    r"(?:###?\s*(?:FILE\s*\d*\s*:?\s*)?|`?([a-zA-Z0-9_.\-/]+/[a-zA-Z0-9_.\-/]+|Containerfile|Makefile|Cargo\.toml|LICENSE|NOTICE\.md|README\.md|CONTRIBUTING\.md|SECURITY\.md)`?\s*\n+)"
    r"```[a-zA-Z0-9_-]*\n(.*?)```",
    re.DOTALL,
)


def normalize_tier(raw_tier: str) -> str:
    """Select the primary reasoning tier from the header string."""
    upper = raw_tier.upper()
    if "HIGH" in upper:
        return "HIGH"
    if "MEDIUM" in upper:
        return "MEDIUM"
    return "LOW"


def parse_markdown_modules(docs_dir: Path) -> list[dict]:
    """Extract all prompts in order from 01_*.md through 08_*.md."""
    md_files = sorted(docs_dir.glob("0[1-8]_*.md"))
    extracted_prompts = []

    for md_path in md_files:
        content = md_path.read_text(encoding="utf-8")
        headers = list(PROMPT_HEADER_RE.finditer(content))
        blocks = list(PROMPT_BLOCK_RE.finditer(content))

        for idx, block_match in enumerate(blocks):
            prompt_id = f"{md_path.name[:2]}.{idx + 1}"
            title = "Unnamed Prompt"
            raw_tier = "MEDIUM"

            if idx < len(headers):
                prompt_id = headers[idx].group(1).strip()
                title = headers[idx].group(2).strip()
                raw_tier = headers[idx].group(3).strip()

            extracted_prompts.append(
                {
                    "id": prompt_id,
                    "title": title,
                    "raw_tier": raw_tier,
                    "tier": normalize_tier(raw_tier),
                    "source_file": md_path.name,
                    "payload": block_match.group(1).strip(),
                }
            )
    return extracted_prompts


def export_prompts_queue(prompts: list[dict], out_dir: Path) -> None:
    """Export all prompt blocks into tier folders for manual or CLI batching."""
    queue_root = out_dir / "prompts_queue"
    for item in prompts:
        tier_dir = queue_root / item["tier"]
        tier_dir.mkdir(parents=True, exist_ok=True)
        safe_id = item["id"].replace(".", "_")
        fname = f"prompt_{safe_id}_{item['source_file']}.txt"
        target_path = tier_dir / fname
        header_comment = (
            f"# PROMPT ID: {item['id']} | TITLE: {item['title']}\n"
            f"# TARGET MODEL: Gemini 3.8 Flash [{item['tier']}] (Raw: {item['raw_tier']})\n"
            f"# SOURCE MODULE: {item['source_file']}\n\n"
        )
        target_path.write_text(header_comment + item["payload"] + "\n", encoding="utf-8")
    print(f"OK: Exported {len(prompts)} prompts to {queue_root}")


def save_generated_files(response_text: str, out_dir: Path, prompt_id: str) -> None:
    """Save raw markdown response and extract individual files into out_dir."""
    logs_dir = out_dir / ".kepler_build_logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    raw_log = logs_dir / f"response_prompt_{prompt_id.replace('.', '_')}.md"
    raw_log.write_text(response_text, encoding="utf-8")

    matches = FILE_BLOCK_RE.findall(response_text)
    for rel_path, code_content in matches:
        rel_path = rel_path.strip().lstrip("/")
        if not rel_path or " " in rel_path:
            continue
        dest = out_dir / rel_path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(code_content.rstrip() + "\n", encoding="utf-8")

        if (
            dest.suffix in {".sh", ".chroot"}
            or "/bin/" in rel_path
            or rel_path.endswith("auto/config")
        ):
            st = os.stat(dest)
            os.chmod(dest, st.st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
        print(f"  -> Wrote file: {rel_path}")


def execute_prompt_via_api(prompt_item: dict, model_name: str, out_dir: Path) -> None:
    """Execute a single prompt against the Gemini API with the target thinking level."""
    try:
        from google import genai
        from google.genai import types
    except ImportError:
        print("ERROR: Install google-genai (`pip install google-genai`) or use `--export-only`.")
        sys.exit(1)

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("ERROR: Environment variable GEMINI_API_KEY is not set.")
        sys.exit(1)

    client = genai.Client(api_key=api_key)

    print(
        f"RUNNING Prompt {prompt_item['id']} [{prompt_item['tier']}]: {prompt_item['title']}..."
    )
    system_instruction = (
        "You are an ASD-STE100 Linux build engineer. "
        "Output each requested file preceded by its exact relative path on a line by itself "
        "(for example: `FILE: path/to/file`), followed immediately by its fenced code block."
    )

    response = client.models.generate_content(
        model=model_name,
        contents=prompt_item["payload"],
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            temperature=0.1,
        ),
    )
    save_generated_files(response.text, out_dir, prompt_item["id"])


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Execute Kepler OS ASD-STE100 Prompts in order."
    )
    parser.add_argument(
        "--docs-dir",
        type=Path,
        default=Path("."),
        help="Directory containing 01_*.md through 08_*.md",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("./kepler-os-build"),
        help="Target directory for generated Kepler OS files",
    )
    parser.add_argument(
        "--tier",
        choices=["ALL", "LOW", "MEDIUM", "HIGH"],
        default="ALL",
        help="Run only prompts matching a specific Gemini 3.8 Flash reasoning tier",
    )
    parser.add_argument(
        "--prompt-id",
        type=str,
        default=None,
        help="Run a single prompt ID (e.g., 1.1 or 5.1)",
    )
    parser.add_argument(
        "--model",
        type=str,
        default="gemini-3.8-flash",
        help="Gemini model identifier",
    )
    parser.add_argument(
        "--export-only",
        action="store_true",
        help="Export prompts into prompts_queue/{LOW,MEDIUM,HIGH}/ without calling API",
    )
    args = parser.parse_args()

    prompts = parse_markdown_modules(args.docs_dir)
    if not prompts:
        print(f"ERROR: No 01_*.md - 08_*.md files found in {args.docs_dir}")
        sys.exit(1)

    if args.tier != "ALL":
        prompts = [p for p in prompts if p["tier"] == args.tier]
    if args.prompt_id:
        prompts = [p for p in prompts if p["id"] == args.prompt_id]

    args.out_dir.mkdir(parents=True, exist_ok=True)

    if args.export_only:
        export_prompts_queue(prompts, args.out_dir)
        return

    state_file = args.out_dir / ".kepler-runner-state.json"
    completed = set()
    if state_file.exists():
        completed = set(json.loads(state_file.read_text(encoding="utf-8")))

    for item in prompts:
        if item["id"] in completed and not args.prompt_id:
            print(f"SKIP: Prompt {item['id']} already completed.")
            continue
        execute_prompt_via_api(item, args.model, args.out_dir)
        completed.add(item["id"])
        state_file.write_text(json.dumps(sorted(completed), indent=2), encoding="utf-8")

    print("OK: All selected Kepler OS prompts completed.")


if __name__ == "__main__":
    main()
