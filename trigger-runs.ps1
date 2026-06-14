#
# trigger-runs.ps1
# Triggers multiple CI pipeline runs by pushing empty commits periodically.
#
# Usage:
#   .\trigger-runs.ps1              # uses defaults
#   .\trigger-runs.ps1 5            # 5 runs
#   .\trigger-runs.ps1 5 120        # 5 runs, 120 seconds between each
#

# ─── Configuration ───────────────────────────────────────────────────────────

param(
    [int]$NumRuns = 5,
    [int]$IntervalSeconds = 2100
)

$Branch = "applications/calcom"

# ─── Script ──────────────────────────────────────────────────────────────────

# Ensure Git and Node are in PATH
$env:PATH = "C:\Program Files\Git\cmd;C:\nvm4w\nodejs;$env:PATH"

Write-Host "============================================"
Write-Host "  CI Pipeline Trigger Script (Windows)"
Write-Host "============================================"
Write-Host "  Runs to trigger : $NumRuns"
Write-Host "  Interval        : ${IntervalSeconds}s between pushes"
Write-Host "  Branch           : $Branch"
Write-Host "  Started at       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "============================================"
Write-Host ""

for ($i = 1; $i -le $NumRuns; $i++) {
    Write-Host "──────────────────────────────────────────"
    Write-Host "  Run $i / $NumRuns"
    Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "──────────────────────────────────────────"

    # Create an empty commit to trigger the pipeline
    git commit --allow-empty -m "Windows Github Job Test - $i/$NumRuns"


    # Push to remote
    git push origin $Branch
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Run $i/$NumRuns pushed successfully"
    } else {
        Write-Host "❌ Run $i/$NumRuns push failed!"
        exit 1
    }

    # Wait before the next push (skip wait after the last run)
    if ($i -lt $NumRuns) {
        Write-Host "⏳ Waiting ${IntervalSeconds}s before next push..."
        Start-Sleep -Seconds $IntervalSeconds
    }

    Write-Host ""
}


Write-Host "============================================"
Write-Host "  All $NumRuns runs triggered successfully!"
Write-Host "  Finished at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "============================================"