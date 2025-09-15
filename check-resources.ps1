# AWS Resource Inventory Script
# This script checks for all AWS resources that could be created by the Terraform configuration
# Run this before deployment to avoid surprise bills

Write-Host "🔍 AWS Resource Inventory Check" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Function to run AWS CLI commands safely
function Invoke-AwsCommand {
    param([string]$Command, [string]$Description)

    Write-Host "📋 Checking $Description..." -ForegroundColor Yellow
    try {
        $result = Invoke-Expression $Command 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        } else {
            Write-Host "   ⚠️  Error running command or no resources found" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "   ❌ Command failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Write-Host "🔐 Testing AWS CLI connection..." -ForegroundColor Green
$testConnection = Invoke-AwsCommand "aws sts get-caller-identity --profile james.emling --query Account --output text" "AWS Connection"
if (-not $testConnection) {
    Write-Host "❌ Cannot connect to AWS. Please check your credentials and profile." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Connected to AWS Account: $testConnection" -ForegroundColor Green
Write-Host ""

# 1. S3 Buckets
Write-Host "📦 S3 BUCKETS" -ForegroundColor Magenta
Write-Host "-------------" -ForegroundColor Magenta
$s3Buckets = Invoke-AwsCommand "aws s3 ls --profile james.emling" "S3 buckets"
if ($s3Buckets) {
    $bucketCount = ($s3Buckets | Measure-Object).Count
    Write-Host "   📊 Found $bucketCount S3 buckets:" -ForegroundColor White
    $s3Buckets | ForEach-Object {
        $parts = $_ -split '\s+', 4
        Write-Host "   • $($parts[2])" -ForegroundColor White
    }
} else {
    Write-Host "   ✅ No S3 buckets found" -ForegroundColor Green
}
Write-Host ""

# 2. VPCs
Write-Host "🏠 VIRTUAL PRIVATE CLOUDS (VPCs)" -ForegroundColor Magenta
Write-Host "---------------------------------" -ForegroundColor Magenta
$vpcs = Invoke-AwsCommand "aws ec2 describe-vpcs --profile james.emling --query 'Vpcs[*].{ID:VpcId,Name:Tags[?Key==`Name`].Value|[0],CIDR:CidrBlock}' --output table" "VPCs"
if ($vpcs) {
    Write-Host "   📊 VPC details:" -ForegroundColor White
    Write-Host $vpcs -ForegroundColor White
} else {
    Write-Host "   ✅ No VPCs found" -ForegroundColor Green
}
Write-Host ""

# 3. KMS Keys
Write-Host "🔐 KMS ENCRYPTION KEYS" -ForegroundColor Magenta
Write-Host "----------------------" -ForegroundColor Magenta
$kmsKeys = Invoke-AwsCommand "aws kms list-keys --profile james.emling --query 'Keys[*].KeyId' --output text" "KMS keys"
if ($kmsKeys -and $kmsKeys.Trim()) {
    $keyCount = ($kmsKeys -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
    Write-Host "   📊 Found $keyCount KMS keys" -ForegroundColor White
} else {
    Write-Host "   ✅ No KMS keys found" -ForegroundColor Green
}
Write-Host ""

# 4. Lambda Functions
Write-Host "⚡ LAMBDA FUNCTIONS" -ForegroundColor Magenta
Write-Host "------------------" -ForegroundColor Magenta
$lambdaFunctions = Invoke-AwsCommand "aws lambda list-functions --profile james.emling --query 'Functions[*].FunctionName' --output text" "Lambda functions"
if ($lambdaFunctions -and $lambdaFunctions.Trim()) {
    $functionCount = ($lambdaFunctions -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
    Write-Host "   📊 Found $functionCount Lambda functions" -ForegroundColor White
} else {
    Write-Host "   ✅ No Lambda functions found" -ForegroundColor Green
}
Write-Host ""

# 5. OpenSearch Collections
Write-Host "🔍 OPENSEARCH COLLECTIONS" -ForegroundColor Magenta
Write-Host "-------------------------" -ForegroundColor Magenta
$opensearchCollections = Invoke-AwsCommand "aws opensearchserverless list-collections --profile james.emling --query 'collectionSummaries[*].name' --output text" "OpenSearch collections"
if ($opensearchCollections -and $opensearchCollections.Trim()) {
    $collectionCount = ($opensearchCollections -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
    Write-Host "   📊 Found $collectionCount OpenSearch collections" -ForegroundColor White
} else {
    Write-Host "   ✅ No OpenSearch collections found" -ForegroundColor Green
}
Write-Host ""

# 6. Bedrock Resources
Write-Host "🤖 BEDROCK AI RESOURCES" -ForegroundColor Magenta
Write-Host "-----------------------" -ForegroundColor Magenta

# Bedrock Agents
$bedrockAgents = Invoke-AwsCommand "aws bedrock-agent list-agents --profile james.emling --query 'agentSummaries[*].agentName' --output text" "Bedrock agents"
if ($bedrockAgents -and $bedrockAgents.Trim()) {
    $agentCount = ($bedrockAgents -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
    Write-Host "   📊 Found $agentCount Bedrock agents" -ForegroundColor White
} else {
    Write-Host "   ✅ No Bedrock agents found" -ForegroundColor Green
}

# Knowledge Bases
$knowledgeBases = Invoke-AwsCommand "aws bedrock-agent list-knowledge-bases --profile james.emling --query 'knowledgeBaseSummaries[*].name' --output text" "Knowledge bases"
if ($knowledgeBases -and $knowledgeBases.Trim()) {
    $kbCount = ($knowledgeBases -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
    Write-Host "   📊 Found $kbCount Knowledge bases" -ForegroundColor White
} else {
    Write-Host "   ✅ No Knowledge bases found" -ForegroundColor Green
}

# Guardrails
$guardrails = Invoke-AwsCommand "aws bedrock list-guardrails --profile james.emling --query 'guardrails[*].name' --output text" "Bedrock guardrails"
if ($guardrails -and $guardrails.Trim()) {
    $guardrailCount = ($guardrails -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
    Write-Host "   📊 Found $guardrailCount Bedrock guardrails" -ForegroundColor White
} else {
    Write-Host "   ✅ No Bedrock guardrails found" -ForegroundColor Green
}
Write-Host ""

# 7. CloudWatch Log Groups
Write-Host "📊 CLOUDWATCH LOG GROUPS" -ForegroundColor Magenta
Write-Host "------------------------" -ForegroundColor Magenta
$logGroups = Invoke-AwsCommand "aws logs describe-log-groups --profile james.emling --query 'logGroups[*].logGroupName' --output text" "CloudWatch log groups"
if ($logGroups -and $logGroups.Trim()) {
    $logCount = ($logGroups -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
    Write-Host "   📊 Found $logCount CloudWatch log groups" -ForegroundColor White
} else {
    Write-Host "   ✅ No CloudWatch log groups found" -ForegroundColor Green
}
Write-Host ""

# 8. IAM Roles
Write-Host "👤 IAM ROLES" -ForegroundColor Magenta
Write-Host "------------" -ForegroundColor Magenta
$iamRoles = Invoke-AwsCommand "aws iam list-roles --profile james.emling --query 'Roles[*].RoleName' --output text" "IAM roles"
if ($iamRoles -and $iamRoles.Trim()) {
    $roleCount = ($iamRoles -split '\s+' | Where-Object { $_ -and $_.Trim() }).Count
    Write-Host "   📊 Found $roleCount IAM roles" -ForegroundColor White
} else {
    Write-Host "   ✅ No IAM roles found" -ForegroundColor Green
}
Write-Host ""

# 9. Security Groups
Write-Host "🔒 SECURITY GROUPS" -ForegroundColor Magenta
Write-Host "------------------" -ForegroundColor Magenta
$securityGroups = Invoke-AwsCommand "aws ec2 describe-security-groups --profile james.emling --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName}' --output table" "Security groups"
if ($securityGroups) {
    Write-Host "   📊 Security group details:" -ForegroundColor White
    Write-Host $securityGroups -ForegroundColor White
} else {
    Write-Host "   ✅ No security groups found" -ForegroundColor Green
}
Write-Host ""

# 10. VPC Endpoints
Write-Host "🌐 VPC ENDPOINTS" -ForegroundColor Magenta
Write-Host "----------------" -ForegroundColor Magenta
$vpcEndpoints = Invoke-AwsCommand "aws ec2 describe-vpc-endpoints --profile james.emling --query 'VpcEndpoints[*].{ID:VpcEndpointId,Service:ServiceName,Type:VpcEndpointType}' --output table" "VPC endpoints"
if ($vpcEndpoints) {
    Write-Host "   📊 VPC endpoint details:" -ForegroundColor White
    Write-Host $vpcEndpoints -ForegroundColor White
} else {
    Write-Host "   ✅ No VPC endpoints found" -ForegroundColor Green
}
Write-Host ""

# Summary
Write-Host "📈 SUMMARY" -ForegroundColor Cyan
Write-Host "==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script checked for all resource types that the Terraform configuration would create." -ForegroundColor White
Write-Host "Review the results above to understand your current AWS resource usage." -ForegroundColor White
Write-Host ""
Write-Host "💡 Tips:" -ForegroundColor Yellow
Write-Host "   • S3 buckets may incur storage costs" -ForegroundColor Yellow
Write-Host "   • Lambda functions may incur compute costs" -ForegroundColor Yellow
Write-Host "   • OpenSearch collections may incur data processing costs" -ForegroundColor Yellow
Write-Host "   • Bedrock usage is pay-per-request" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ Safe to proceed with Terraform deployment if no unexpected resources found." -ForegroundColor Green
