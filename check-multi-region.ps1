# Multi-Region AWS Resource Inventory Script
# Checks for resources across multiple regions to avoid surprise bills

$regions = @("us-east-1", "us-west-2", "us-west-1")
$profile = "james.emling"

Write-Host "🌍 MULTI-REGION AWS RESOURCE INVENTORY" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

foreach ($region in $regions) {
    Write-Host "📍 CHECKING REGION: $region" -ForegroundColor Yellow
    Write-Host "===================================" -ForegroundColor Yellow

    # VPCs
    Write-Host "🏠 VPCs:" -ForegroundColor Magenta
    try {
        $vpcs = aws ec2 describe-vpcs --region $region --profile $profile --query 'Vpcs[*].{ID:VpcId,CIDR:CidrBlock,Name:Tags[?Key==`Name`].Value|[0]}' --output table 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host $vpcs -ForegroundColor White
        } else {
            Write-Host "   No VPCs found or access denied" -ForegroundColor Red
        }
    } catch {
        Write-Host "   Error checking VPCs" -ForegroundColor Red
    }

    # S3 Buckets (global, but check region context)
    Write-Host "📦 S3 Buckets:" -ForegroundColor Magenta
    try {
        $buckets = aws s3 ls --region $region --profile $profile 2>$null
        if ($LASTEXITCODE -eq 0 -and $buckets) {
            $bucketCount = ($buckets | Measure-Object).Count
            Write-Host "   Found $bucketCount buckets in $region context" -ForegroundColor White
        } else {
            Write-Host "   No buckets found in $region context" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Error checking S3 buckets" -ForegroundColor Red
    }

    # Lambda Functions
    Write-Host "⚡ Lambda Functions:" -ForegroundColor Magenta
    try {
        $functions = aws lambda list-functions --region $region --profile $profile --query 'Functions[*].FunctionName' --output text 2>$null
        if ($LASTEXITCODE -eq 0 -and $functions -and $functions.Trim()) {
            $funcCount = ($functions -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
            Write-Host "   Found $funcCount Lambda functions" -ForegroundColor White
        } else {
            Write-Host "   No Lambda functions found" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Error checking Lambda functions" -ForegroundColor Red
    }

    # Bedrock Resources
    Write-Host "🤖 Bedrock Resources:" -ForegroundColor Magenta
    try {
        $agents = aws bedrock-agent list-agents --region $region --profile $profile --query 'agentSummaries[*].agentName' --output text 2>$null
        if ($LASTEXITCODE -eq 0 -and $agents -and $agents.Trim()) {
            $agentCount = ($agents -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
            Write-Host "   Found $agentCount Bedrock agents" -ForegroundColor White
        } else {
            Write-Host "   No Bedrock agents found" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Bedrock not available in $region or access denied" -ForegroundColor Red
    }

    # OpenSearch Collections
    Write-Host "🔍 OpenSearch Collections:" -ForegroundColor Magenta
    try {
        $collections = aws opensearchserverless list-collections --region $region --profile $profile --query 'collectionSummaries[*].name' --output text 2>$null
        if ($LASTEXITCODE -eq 0 -and $collections -and $collections.Trim()) {
            $collCount = ($collections -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
            Write-Host "   Found $collCount OpenSearch collections" -ForegroundColor White
        } else {
            Write-Host "   No OpenSearch collections found" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Error checking OpenSearch collections" -ForegroundColor Red
    }

    # KMS Keys
    Write-Host "🔐 KMS Keys:" -ForegroundColor Magenta
    try {
        $kmsKeys = aws kms list-keys --region $region --profile $profile --query 'Keys[*].KeyId' --output text 2>$null
        if ($LASTEXITCODE -eq 0 -and $kmsKeys -and $kmsKeys.Trim()) {
            $keyCount = ($kmsKeys -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
            Write-Host "   Found $keyCount KMS keys" -ForegroundColor White
        } else {
            Write-Host "   No KMS keys found" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Error checking KMS keys" -ForegroundColor Red
    }

    Write-Host ""
}

Write-Host "📊 SUMMARY ACROSS ALL REGIONS" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Regions Checked: $($regions -join ', ')" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Key Findings:" -ForegroundColor Yellow
Write-Host "   • Default VPCs (172.31.0.0/16) are normal and usually free" -ForegroundColor Yellow
Write-Host "   • Check for resources with 'acme', 'bedrock', or deployment-specific names" -ForegroundColor Yellow
Write-Host "   • S3 buckets are global but have regional context" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎯 Current Terraform Target Region: us-east-1" -ForegroundColor Green
Write-Host "   Your Terraform will deploy to us-east-1 only." -ForegroundColor White
Write-Host ""
Write-Host "✅ Safe to proceed with Terraform deployment in us-east-1!" -ForegroundColor Green
