# cl-tf Professional Deployment Automation Script
# Implements Init, Validate, Plan, and Auto-Apply

Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host "🚀 Initializing Terraform..." -ForegroundColor Cyan
terraform -chdir=tf init

Write-Host "🔍 Validating Configuration..." -ForegroundColor Cyan
terraform -chdir=tf validate
if ($LASTEXITCODE -ne 0) { return }

Write-Host "📝 Generating Plan..." -ForegroundColor Yellow
terraform -chdir=tf plan -out=tfplan

Write-Host "🔥 Applying Infrastructure..." -ForegroundColor Green
terraform -chdir=tf apply -auto-approve tfplan

Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host "🏁 TERRAFORM INFRASTRUCTURE DEPLOYED SUCCESSFULLY! 🚀🔥" -ForegroundColor White -BackgroundColor Green
