# cl-tf Direct Deployment Script
# No variables, No confusion

$ErrorActionPreference = "Stop"

Write-Host "-------------------------------------------"
Write-Host ">>> Initializing Terraform..."
terraform -chdir=tf init

Write-Host ">>> Validating Configuration..."
terraform -chdir=tf validate

Write-Host ">>> Generating Plan..."
terraform -chdir=tf plan -out=tfplan

Write-Host ">>> Applying Infrastructure..."
terraform -chdir=tf apply -auto-approve tfplan

Write-Host "-------------------------------------------"
Write-Host ">>> SUCCESS: TERRAFORM INFRASTRUCTURE DEPLOYED! <<<"
