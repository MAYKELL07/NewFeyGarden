# FeyGarden Development Server
# Starts Rojo in serve mode for live syncing with Roblox Studio

Write-Host "🌿 Starting FeyGarden Development Server..." -ForegroundColor Green
Write-Host ""

# Check if rojo is installed
$rojoExists = Get-Command rojo -ErrorAction SilentlyContinue
if (-not $rojoExists) {
    Write-Host "❌ Error: Rojo is not installed!" -ForegroundColor Red
    Write-Host "Please install Rojo from: https://rojo.space/docs/v7/getting-started/installation/" -ForegroundColor Yellow
    exit 1
}

Write-Host "📡 Starting Rojo server..." -ForegroundColor Cyan
Write-Host "Keep this window open while developing!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open Roblox Studio" -ForegroundColor White
Write-Host "2. Install the Rojo plugin (if you haven't)" -ForegroundColor White
Write-Host "3. Click 'Connect' in the Rojo plugin" -ForegroundColor White
Write-Host "4. Your code will sync automatically when you save files!" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Cyan

rojo serve
