# cl-cfn Professional Deployment Automation Script (V3 - Native Deploy)
$stacks = @(
    @{ Name = "cl-cfn-vpc-stack"; Path = "cfn/vpc.yaml"; Caps = "CAPABILITY_IAM" },
    @{ Name = "cl-cfn-iam-stack"; Path = "cfn/iam.yaml"; Caps = "CAPABILITY_NAMED_IAM" },
    @{ Name = "cl-cfn-security-stack"; Path = "cfn/security.yaml"; Caps = "" },
    @{ Name = "cl-cfn-compute-stack"; Path = "cfn/compute.yaml"; Caps = "CAPABILITY_IAM" }
)

foreach ($stack in $stacks) {
    Write-Host "-------------------------------------------" -ForegroundColor Gray
    Write-Host "Validating template: $($stack.Name)..." -ForegroundColor Cyan
    aws cloudformation validate-template --template-body "file://$($stack.Path)"
    if ($LASTEXITCODE -ne 0) { return }

    Write-Host "Deploying stack: $($stack.Name)..." -ForegroundColor Yellow
    
    $args = @("cloudformation", "deploy", "--stack-name", $stack.Name, "--template-file", $stack.Path)
    if ($stack.Caps -ne "") {
        $args += @("--capabilities", $stack.Caps)
    }

    # "aws cloudformation deploy" handles "No Changes" automatically!
    aws @args

    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 255) {
        Write-Host "SUCCESS: $($stack.Name) is up to date." -ForegroundColor Green
    } else {
        Write-Host "FAILED: Error deploying $($stack.Name)." -ForegroundColor Red
        return
    }
}

Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host "ALL STACKS VERIFIED AND DEPLOYED!" -ForegroundColor White -BackgroundColor Green
