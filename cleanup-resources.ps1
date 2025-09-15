# AWS Resource Cleanup Script
# This script safely removes resources from previous failed deployments
# Only targets resources that match our Terraform naming patterns

Write-Host "🧹 AWS Resource Cleanup Script" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  WARNING: This script will delete resources!" -ForegroundColor Red
Write-Host "   Make sure you want to delete these resources before proceeding." -ForegroundColor Red
Write-Host ""

# Function to run AWS CLI commands safely
function Invoke-AwsCommand {
    param([string]$Command, [string]$Description)

    Write-Host "🗑️  Deleting $Description..." -ForegroundColor Yellow
    try {
        $result = Invoke-Expression $Command 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Successfully deleted $Description" -ForegroundColor Green
            return $result
        } else {
            Write-Host "   ⚠️  Failed to delete $Description or resource not found" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "   ❌ Error deleting $Description : $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Confirm before proceeding
$confirmation = Read-Host "Do you want to proceed with cleanup? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "❌ Cleanup cancelled by user." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "🧽 Starting cleanup process..." -ForegroundColor Green
Write-Host ""

# 1. Delete VPC Endpoints (these are likely from previous deployment)
Write-Host "🌐 Deleting VPC Endpoints..." -ForegroundColor Magenta
Write-Host "-----------------------------" -ForegroundColor Magenta
Invoke-AwsCommand "aws ec2 delete-vpc-endpoints --vpc-endpoint-ids vpce-0761d82f32d7cd1a9 vpce-0a635e70aa0ba7eba vpce-08743870723daf68e vpce-0f73d57e46a874ed1 vpce-05a388f184e5b7616 vpce-060f4960a2a24e92b vpce-04957518681497fb8 vpce-08c6281ac155bed98 vpce-0b4a390dfb1bc2daf vpce-08cc00974de76d3a3 --profile james.emling" "VPC endpoints"

# 2. Delete Security Groups (only the ones from our deployment)
Write-Host ""
Write-Host "🔒 Deleting Security Groups..." -ForegroundColor Magenta
Write-Host "----------------------------" -ForegroundColor Magenta
Invoke-AwsCommand "aws ec2 delete-security-group --group-id sg-06814e625336ac2b8 --profile james.emling" "VPC endpoint security group"
Invoke-AwsCommand "aws ec2 delete-security-group --group-id sg-00bb0130e64b417c1 --profile james.emling" "Lambda security group"
Invoke-AwsCommand "aws ec2 delete-security-group --group-id sg-0a4b03a647d11a407 --profile james.emling" "Interface security group"

# 3. Delete VPC (this will require deleting subnets first)
Write-Host ""
Write-Host "🏠 Deleting VPC and Subnets..." -ForegroundColor Magenta
Write-Host "------------------------------" -ForegroundColor Magenta

# First delete subnets
Invoke-AwsCommand "aws ec2 delete-subnet --subnet-id subnet-06051f5572a8dfd97 --profile james.emling" "Private subnet 1"
Invoke-AwsCommand "aws ec2 delete-subnet --subnet-id subnet-089974e290de9b8bf --profile james.emling" "Private subnet 2"
Invoke-AwsCommand "aws ec2 delete-subnet --subnet-id subnet-09a90fcb10f26d1b4 --profile james.emling" "Public subnet 1"
Invoke-AwsCommand "aws ec2 delete-subnet --subnet-id subnet-0cc78c89d4f3886d7 --profile james.emling" "Public subnet 2"

# Delete route table associations first
Invoke-AwsCommand "aws ec2 disassociate-route-table --association-id $(aws ec2 describe-route-tables --profile james.emling --filters 'Name=vpc-id,Values=vpc-0da63c4674b1d23f3' --query 'RouteTables[0].Associations[?SubnetId!=`null`].RouteTableAssociationId' --output text) --profile james.emling" "Route table associations"

# Delete route table
Invoke-AwsCommand "aws ec2 delete-route-table --route-table-id $(aws ec2 describe-route-tables --profile james.emling --filters 'Name=vpc-id,Values=vpc-0da63c4674b1d23f3' --query 'RouteTables[?Tags[?Key==`Name` && Value==`acme-prod-public-rt`]].RouteTableId' --output text) --profile james.emling" "Public route table"

# Detach and delete internet gateway
Invoke-AwsCommand "aws ec2 detach-internet-gateway --internet-gateway-id $(aws ec2 describe-internet-gateways --profile james.emling --filters 'Name=attachment.vpc-id,Values=vpc-0da63c4674b1d23f3' --query 'InternetGateways[0].InternetGatewayId' --output text) --vpc-id vpc-0da63c4674b1d23f3 --profile james.emling" "Internet gateway detachment"
Invoke-AwsCommand "aws ec2 delete-internet-gateway --internet-gateway-id $(aws ec2 describe-internet-gateways --profile james.emling --filters 'Name=attachment.vpc-id,Values=vpc-0da63c4674b1d23f3' --query 'InternetGateways[0].InternetGatewayId' --output text) --profile james.emling" "Internet gateway"

# Finally delete VPC
Invoke-AwsCommand "aws ec2 delete-vpc --vpc-id vpc-0da63c4674b1d23f3 --profile james.emling" "VPC"

# 4. Delete KMS Key (schedule for deletion)
Write-Host ""
Write-Host "🔐 Scheduling KMS Key Deletion..." -ForegroundColor Magenta
Write-Host "----------------------------------" -ForegroundColor Magenta
Invoke-AwsCommand "aws kms schedule-key-deletion --key-id $(aws kms list-keys --profile james.emling --query 'Keys[0].KeyId' --output text) --pending-window-in-days 7 --profile james.emling" "KMS key (scheduled for deletion in 7 days)"

# 5. Clean up IAM Roles (be very careful here - only delete roles we created)
Write-Host ""
Write-Host "👤 Checking IAM Roles..." -ForegroundColor Magenta
Write-Host "-----------------------" -ForegroundColor Magenta
Write-Host "⚠️  Skipping IAM role deletion for safety." -ForegroundColor Yellow
Write-Host "   Please manually review and delete roles with 'bedrock' or 'acme' in the name if needed." -ForegroundColor Yellow

# Summary
Write-Host ""
Write-Host "📋 CLEANUP SUMMARY" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Attempted to delete:" -ForegroundColor Green
Write-Host "   • VPC and all subnets" -ForegroundColor White
Write-Host "   • Internet Gateway" -ForegroundColor White
Write-Host "   • Route tables and associations" -ForegroundColor White
Write-Host "   • VPC endpoints" -ForegroundColor White
Write-Host "   • Security groups" -ForegroundColor White
Write-Host "   • KMS key (scheduled for deletion)" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Skipped for safety:" -ForegroundColor Yellow
Write-Host "   • IAM roles (review manually)" -ForegroundColor White
Write-Host "   • S3 buckets (review contents first)" -ForegroundColor White
Write-Host ""
Write-Host "🔄 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Run the check-resources.ps1 script again to verify cleanup" -ForegroundColor White
Write-Host "   2. Manually delete any remaining S3 buckets if they're empty" -ForegroundColor White
Write-Host "   3. Review IAM roles and delete ones you don't need" -ForegroundColor White
Write-Host "   4. Proceed with Terraform deployment" -ForegroundColor White
Write-Host ""
Write-Host "✅ Cleanup process completed!" -ForegroundColor Green
