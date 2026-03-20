#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./deploy.sh [--plan|--apply] [terraform args...]

  --plan   Run terraform plan
  --apply  Run terraform apply (default)
EOF
}

ACTION="apply"
ACTION_SET=""
TERRAFORM_ARGS=()
for arg in "$@"; do
  case "${arg}" in
    --help|-h)
      usage
      exit 0
      ;;
    --plan)
      if [[ -n "${ACTION_SET}" && "${ACTION}" != "plan" ]]; then
        echo "Error: cannot specify both --plan and --apply." >&2
        usage >&2
        exit 2
      fi
      ACTION="plan"
      ACTION_SET="1"
      ;;
    --apply)
      if [[ -n "${ACTION_SET}" && "${ACTION}" != "apply" ]]; then
        echo "Error: cannot specify both --plan and --apply." >&2
        usage >&2
        exit 2
      fi
      ACTION="apply"
      ACTION_SET="1"
      ;;
    *)
      TERRAFORM_ARGS+=("${arg}")
      ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pushd "${SCRIPT_DIR}/stack" >/dev/null
trap 'popd >/dev/null || true' EXIT

echo "Getting AWS account ID and CloudFront distribution information..."

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get all CloudFront distributions and find the one with "fryrank-app" tag value
DIST_ID=""
for dist_id in $(aws cloudfront list-distributions --query "DistributionList.Items[].Id" --output text); do
    tag_key=$(aws cloudfront list-tags-for-resource --resource "arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${dist_id}" --query "Tags.Items[?Value==\`fryrank-app\`].Key" --output text)
    if [ -n "$tag_key" ]; then
        DIST_ID="$dist_id"
        break
    fi
done

if [ -z "${DIST_ID}" ]; then
    echo "No CloudFront distribution found for this account. Please run terraform apply first to create the distribution."
    exit 1
fi

WEB_ACL_ARN=""
DIST_WEB_ACL="$(aws cloudfront get-distribution-config --id "${DIST_ID}" --query "DistributionConfig.WebACLId" --output text)"
if [[ "${DIST_WEB_ACL}" != "None" && "${DIST_WEB_ACL}" != "null" && -n "${DIST_WEB_ACL}" ]]; then
    WEB_ACL_ARN="${DIST_WEB_ACL}"
else
    WEB_ACL_ARN="$(aws wafv2 list-web-acls --region us-east-1 --scope CLOUDFRONT --query "WebACLs[?starts_with(Name, \`CreatedByCloudFront\`)] | [0].ARN" --output text)"
    if [[ "${WEB_ACL_ARN}" == "None" || "${WEB_ACL_ARN}" == "null" ]]; then
        WEB_ACL_ARN=""
    fi
fi

if [ -z "${WEB_ACL_ARN}" ]; then
    echo "Could not determine a Web ACL for the CloudFront distribution."
    exit 1
fi

echo "CloudFront Distribution ID: ${DIST_ID}"
echo "Web ACL ARN: ${WEB_ACL_ARN}"

export TF_VAR_cloudfront_web_acl_arn="${WEB_ACL_ARN}"

echo "TF_VAR_cloudfront_web_acl_arn=${WEB_ACL_ARN}"

if [[ "${ACTION}" == "apply" ]]; then
    # If the "live" Lambda aliases already exist (common in shared environments),
    # Terraform needs them in state before it can update them to point at newly
    # published versions.
    if [[ -d .terraform ]] && [[ -f scripts/import_lambda_aliases.py ]]; then
        echo "Importing existing Lambda live aliases (if needed)..."
        if command -v python3 >/dev/null 2>&1; then
            python3 scripts/import_lambda_aliases.py
        else
            python scripts/import_lambda_aliases.py
        fi
    fi
fi

echo "Running terraform ${ACTION}..."
terraform "${ACTION}" "${TERRAFORM_ARGS[@]}"
