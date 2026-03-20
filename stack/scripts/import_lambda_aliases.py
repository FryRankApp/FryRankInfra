#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


LAMBDA_ALIAS_NAME = "live"
TERRAFORM_ALIAS_RESOURCE_NAME = "fryrank_api_lambdas_live"

# for_each keys in stack/lambda.tf -> actual Lambda function names in AWS
FUNCTIONS: list[tuple[str, str]] = [
    ("get_all_reviews", "getAllReviews"),
    ("add_new_review", "addNewReview"),
    ("delete_review", "deleteReview"),
    ("get_aggregate_review_information", "getAggregateReviewInformation"),
    ("get_top_reviews", "getRecentReviews"),
    ("get_public_user_metadata", "getPublicUserMetadata"),
    ("put_public_user_metadata", "putPublicUserMetadata"),
    ("upsert_public_user_metadata", "upsertPublicUserMetadata"),
]


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


def _terraform_state_has(addr: str) -> bool:
    cp = _run(["terraform", "state", "show", addr])
    return cp.returncode == 0


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

    imported = 0
    skipped_in_state = 0
    skipped_missing_in_aws = 0

    for tf_key, fn_name in FUNCTIONS:
        addr = f'aws_lambda_alias.{TERRAFORM_ALIAS_RESOURCE_NAME}["{tf_key}"]'
        if _terraform_state_has(addr):
            skipped_in_state += 1
            continue

        if not _aws_alias_exists(fn_name, LAMBDA_ALIAS_NAME):
            skipped_missing_in_aws += 1
            continue

        print(f'Importing {addr} <- {fn_name}/{LAMBDA_ALIAS_NAME}')
        _terraform_import(addr, f"{fn_name}/{LAMBDA_ALIAS_NAME}")
        imported += 1

    print(
        "Alias import summary: "
        f"imported={imported}, "
        f"already_in_state={skipped_in_state}, "
        f"missing_in_aws={skipped_missing_in_aws}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

