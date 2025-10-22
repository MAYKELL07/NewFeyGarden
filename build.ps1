# FeyGarden Build Script
# Builds the Roblox place file from source

Write-Host "🌿 Building FeyGarden..." -ForegroundColor Green

# Check if rojo is installed
$rojoExists = Get-Command rojo -ErrorAction SilentlyContinue
if (-not $rojoExists) {
    Write-Host "❌ Error: Rojo is not installed!" -ForegroundColor Red
    Write-Host "Please install Rojo from: https://rojo.space/docs/v7/getting-started/installation/" -ForegroundColor Yellow
    exit 1
}

# Build the place file
Write-Host "Building place file..." -ForegroundColor Cyan
rojo build -o FeyGarden.rbxl

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful! Place file created: FeyGarden.rbxl" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Double-click FeyGarden.rbxl to open in Roblox Studio" -ForegroundColor White
    Write-Host "2. Press F5 to play the game" -ForegroundColor White
    Write-Host "3. Have fun building your magical garden! 🌱✨" -ForegroundColor White
} else {
    Write-Host "❌ Build failed! Check the errors above." -ForegroundColor Red
    exit 1
}
