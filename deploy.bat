@echo off
setlocal enabledelayedexpansion

pushd "%~dp0stack" || exit /b 1
set "EXIT_CODE=0"

echo Getting AWS account ID and CloudFront distribution information...

for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set ACCOUNT_ID=%%i

rem Get all CloudFront distributions and find the one with "fryrank-app" tag value
for /f "tokens=*" %%i in ('aws cloudfront list-distributions --query "DistributionList.Items[].Id" --output text') do (
    for /f "tokens=*" %%j in ('aws cloudfront list-tags-for-resource --resource "arn:aws:cloudfront::%ACCOUNT_ID%:distribution/%%i" --query "Tags.Items[?Value==`fryrank-app`].Key" --output text') do (
        if not "%%j"=="" (
            set DIST_ID=%%i
            goto :found_distribution
        )
    )
)

:found_distribution
if "%DIST_ID%"=="" (
    echo No CloudFront distribution with tag 'fryrank-app' found for this account.
    set "EXIT_CODE=1"
    goto :cleanup
)

set "WEB_ACL_ARN="

rem Prefer the Web ACL already attached to the distribution (avoids picking the wrong one).
set "DIST_WEB_ACL="
for /f "tokens=*" %%i in ('aws cloudfront get-distribution-config --id %DIST_ID% --query "DistributionConfig.WebACLId" --output text') do set DIST_WEB_ACL=%%i
if /i not "%DIST_WEB_ACL%"=="None" if /i not "%DIST_WEB_ACL%"=="null" if not "%DIST_WEB_ACL%"=="" (
    set "WEB_ACL_ARN=%DIST_WEB_ACL%"
) else (
    rem Fallback: first Web ACL whose name starts with "CreatedByCloudFront"
    for /f "tokens=*" %%i in ('aws wafv2 list-web-acls --region us-east-1 --scope CLOUDFRONT --query "WebACLs[?starts_with(Name, `CreatedByCloudFront`)] | [0].ARN" --output text') do set WEB_ACL_ARN=%%i
    if /i "%WEB_ACL_ARN%"=="None" set "WEB_ACL_ARN="
    if /i "%WEB_ACL_ARN%"=="null" set "WEB_ACL_ARN="
)

echo CloudFront Distribution ID: %DIST_ID%
echo Web ACL ARN: %WEB_ACL_ARN%

if "%WEB_ACL_ARN%"=="" (
    echo Could not determine a Web ACL for the CloudFront distribution.
    set "EXIT_CODE=1"
    goto :cleanup
)

rem Terraform picks up input variables from environment variables prefixed with TF_VAR_
set "TF_VAR_cloudfront_web_acl_arn=%WEB_ACL_ARN%"

echo TF_VAR_cloudfront_web_acl_arn=%WEB_ACL_ARN%

echo Running terraform apply...
terraform apply

:cleanup
popd
exit /b %EXIT_CODE%
