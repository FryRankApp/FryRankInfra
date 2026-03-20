#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


LAMBDA_ALIAS_NAME = "live"
TERRAFORM_ALIAS_RESOURCE_NAME = "fryrank_api_lambdas_live"


def _run(cmd: list[str], *, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        text=True,
        capture_output=True,
        check=check,
    )


def _has_alias_resource_config(repo_stack_dir: Path) -> bool:
    # Import requires the resource to exist in config; avoid noisy failures.
    needle = f'resource "aws_lambda_alias" "{TERRAFORM_ALIAS_RESOURCE_NAME}"'
    for tf_file in repo_stack_dir.rglob("*.tf"):
        try:
            if needle in tf_file.read_text(encoding="utf-8", errors="ignore"):
                return True
        except OSError:
            continue
    return False


def _extract_brace_block(text: str, open_brace_index: int) -> str | None:
    depth = 0
    for i in range(open_brace_index, len(text)):
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[open_brace_index : i + 1]
    return None


def _load_tf_key_by_function_name_from_lambda_tf(repo_stack_dir: Path) -> dict[str, str]:
    """
    Loads mapping of (Lambda function name -> for_each key) from stack/lambda.tf locals.

    Expected shape:
      locals {
        lambda_functions = {
          some_key = {
            name = "someFunctionName"
            handler = "..."
          }
        }
      }
    """
    lambda_tf = repo_stack_dir / "lambda.tf"
    if not lambda_tf.exists():
        return {}

    text = lambda_tf.read_text(encoding="utf-8", errors="ignore")
    m = re.search(r"(?m)^\s*lambda_functions\s*=\s*\{", text)
    if not m:
        return {}

    open_brace_index = m.end() - 1
    block = _extract_brace_block(text, open_brace_index)
    if not block:
        return {}

    tf_key_by_function_name: dict[str, str] = {}
    entry_start_re = re.compile(r"(?m)^\s*([A-Za-z0-9_]+)\s*=\s*\{")
    name_re = re.compile(r'(?m)^\s*name\s*=\s*"([^"]+)"\s*,?\s*$')

    for m_entry in entry_start_re.finditer(block):
        tf_key = m_entry.group(1)
        open_index = m_entry.end() - 1  # points at "{"
        entry_block = _extract_brace_block(block, open_index)
        if not entry_block:
            continue

        m_name = name_re.search(entry_block)
        if not m_name:
            continue

        function_name = m_name.group(1)
        tf_key_by_function_name.setdefault(function_name, tf_key)

    return tf_key_by_function_name


def _terraform_state_has(addr: str) -> bool:
    cp = _run(["terraform", "state", "show", addr])
    return cp.returncode == 0


def _aws_list_function_names() -> list[str]:
    cp = _run(
        [
            "aws",
            "lambda",
            "list-functions",
            "--no-paginate",
            "--query",
            "Functions[].FunctionName",
            "--output",
            "text",
        ]
    )
    if cp.returncode != 0:
        sys.stderr.write(cp.stdout)
        sys.stderr.write(cp.stderr)
        raise SystemExit(cp.returncode)

    return [n for n in cp.stdout.split() if n.strip()]


def _aws_alias_exists(function_name: str, alias_name: str) -> bool:
    cp = _run(["aws", "lambda", "get-alias", "--function-name", function_name, "--name", alias_name])
    return cp.returncode == 0


def _terraform_import(addr: str, import_id: str) -> None:
    cp = _run(["terraform", "import", addr, import_id])
    if cp.returncode != 0:
        sys.stderr.write(cp.stdout)
        sys.stderr.write(cp.stderr)
        raise SystemExit(cp.returncode)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Idempotently import existing Lambda aliases into Terraform state (for CI/CD + local applies)."
    )
    parser.add_argument(
        "--stack-dir",
        default=".",
        help="Path to the Terraform stack working directory (default: current directory).",
    )
    args = parser.parse_args()

    stack_dir = Path(args.stack_dir).resolve()
    os.chdir(stack_dir)

    if not _has_alias_resource_config(stack_dir):
        print("No aws_lambda_alias resource in config; skipping alias import.")
        return 0

    tf_key_by_function_name = _load_tf_key_by_function_name_from_lambda_tf(stack_dir)
    if not tf_key_by_function_name:
        sys.stderr.write("Failed to load lambda.tf mapping (locals.lambda_functions.name).\n")
        return 2

    aws_function_names = _aws_list_function_names()

    imported = 0
    skipped_in_state = 0
    skipped_missing_in_aws = 0
    skipped_not_managed_by_tf = 0

    for function_name in aws_function_names:
        tf_key = tf_key_by_function_name.get(function_name)
        if not tf_key:
            skipped_not_managed_by_tf += 1
            continue

        addr = f'aws_lambda_alias.{TERRAFORM_ALIAS_RESOURCE_NAME}["{tf_key}"]'
        if _terraform_state_has(addr):
            skipped_in_state += 1
            continue

        if not _aws_alias_exists(function_name, LAMBDA_ALIAS_NAME):
            skipped_missing_in_aws += 1
            continue

        print(f'Importing {addr} <- {function_name}/{LAMBDA_ALIAS_NAME}')
        _terraform_import(addr, f"{function_name}/{LAMBDA_ALIAS_NAME}")
        imported += 1

    print(
        "Alias import summary: "
        f"imported={imported}, "
        f"already_in_state={skipped_in_state}, "
        f"missing_in_aws={skipped_missing_in_aws}, "
        f"not_managed_by_tf={skipped_not_managed_by_tf}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

