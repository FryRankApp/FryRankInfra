#!/bin/bash

set -euo pipefail

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

# arn:.../webacl/<name>/<id>
WEB_ACL_ID="${WEB_ACL_ARN##*/}"
WEB_ACL_NAME="${WEB_ACL_ARN%/*}"
WEB_ACL_NAME="${WEB_ACL_NAME##*/}"

if [ -z "${WEB_ACL_ID}" ] || [ -z "${WEB_ACL_NAME}" ] || [ "${WEB_ACL_ID}" = "${WEB_ACL_ARN}" ]; then
    echo "Could not parse Web ACL name/ID from ARN: ${WEB_ACL_ARN}"
    exit 1
fi

echo "CloudFront Distribution ID: ${DIST_ID}"
echo "Web ACL ARN: ${WEB_ACL_ARN}"
echo "Web ACL ID: ${WEB_ACL_ID}"

export TF_VAR_cloudfront_web_acl_arn="${WEB_ACL_ARN}"
export TF_VAR_cloudfront_web_acl_name="${WEB_ACL_NAME}"

echo "TF_VAR_cloudfront_web_acl_arn=${WEB_ACL_ARN}"
echo "TF_VAR_cloudfront_web_acl_name=${WEB_ACL_NAME}"

echo "Importing Web ACL into Terraform state..."
if terraform state list aws_wafv2_web_acl.cloudfront_web_acl >/dev/null 2>&1; then
    echo "Web ACL already imported, skipping import step."
else
    terraform import aws_wafv2_web_acl.cloudfront_web_acl "${WEB_ACL_ID}/${WEB_ACL_NAME}/CLOUDFRONT"
fi

echo "Running terraform apply..."
terraform apply
