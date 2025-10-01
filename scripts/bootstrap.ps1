# scripts/bootstrap.ps1
# One-click setup and audit execution

param(
    [string]$OutputRoot = ".\output",
    [switch]$IncludeGitHub,
    [string]$GitHubOrg,
    [switch]$IncludeAzDO,
    [switch]$SkipInstall
)

Write-Host "🚀 MFA Phase 2 Audit Kit - Bootstrap" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# 1) Install required modules
if (-not $SkipInstall) {
    Write-Host "📦 Installing required PowerShell modules..." -ForegroundColor Yellow
    
    $modules = @(
        "Microsoft.Graph",
        "Az.Accounts", 
        "Az.Resources",
        "Pester"
    )
    
    foreach ($module in $modules) {
        Write-Host "  Installing $module..." -ForegroundColor Gray
        try {
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
            Write-Host "  ✅ $module installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Failed to install $module: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 2) Create output directory
if (-not (Test-Path $OutputRoot)) {
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
    Write-Host "📁 Created output directory: $OutputRoot" -ForegroundColor Green
}

# 3) Run the audit
Write-Host "🔍 Running MFA Phase 2 audit..." -ForegroundColor Yellow
Write-Host "   This may take several minutes depending on your tenant size." -ForegroundColor Gray

try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    & "$PSScriptRoot\Run-Audit.ps1" -OutputRoot $OutputRoot -IncludeGitHub:$IncludeGitHub -IncludeAzDO:$IncludeAzDO
    
    $stopwatch.Stop()
    $duration = $stopwatch.Elapsed.ToString("mm\:ss")
    
    Write-Host "✅ Audit completed successfully in $duration" -ForegroundColor Green
    
    # 4) Show results summary
    Write-Host "`n📊 Audit Results Summary:" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    
    $outputFiles = @(
        "Admins_ByRole.csv",
        "CA_Policies.csv", 
        "Admins_AuthMethods.csv",
        "ServicePrincipals.csv",
        "ARM_SignIns.csv"
    )
    
    foreach ($file in $outputFiles) {
        $path = Join-Path $OutputRoot $file
        if (Test-Path $path) {
            $count = (Import-Csv $path).Count
            Write-Host "  📄 $file`: $count records" -ForegroundColor White
        } else {
            Write-Host "  ❌ $file`: Not found" -ForegroundColor Red
        }
    }
    
    # 5) Show next steps
    Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "==============" -ForegroundColor Cyan
    Write-Host "1. Review the CSV files in: $OutputRoot" -ForegroundColor White
    Write-Host "2. Check for break-glass accounts in Admins_ByRole.csv" -ForegroundColor White
    Write-Host "3. Review Conditional Access policies in CA_Policies.csv" -ForegroundColor White
    Write-Host "4. Address high-risk findings immediately" -ForegroundColor White
    Write-Host "5. Plan migration of service principals to Managed Identities" -ForegroundColor White
    
    Write-Host "`n📚 For detailed guidance, see:" -ForegroundColor Cyan
    Write-Host "   - docs/quickstart.md" -ForegroundColor White
    Write-Host "   - docs/permissions.md" -ForegroundColor White
    Write-Host "   - examples/ directory for sample outputs" -ForegroundColor White
    
} catch {
    Write-Host "❌ Audit failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Check the error details above and ensure you have the required permissions." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n🎉 Bootstrap complete!" -ForegroundColor Green
