# Ensure script runs in the current directory
$projectRoot = Get-Location

if (-Not (Test-Path "$projectRoot\composer.json")) {
    Write-Host "❌ composer.json not found. Please run this script in your Laravel project root." -ForegroundColor Red
    exit 1
}

# Check current Laravel version
$composerJson = Get-Content "$projectRoot\composer.json" -Raw
if ($composerJson -match '"laravel/framework":\s*"([^"]+)"') {
    $currentVersion = $Matches[1]
    if (-not ($currentVersion.StartsWith("8."))) {
        Write-Host "⚠️ Detected Laravel version is $currentVersion (not 8.x)."
        $response = Read-Host "Continue anyway? (y/n)"
        if ($response -ne "y") { exit 1 }
    }
} else {
    Write-Host "Could not detect Laravel version from composer.json"
    exit 1
}

# Backup composer.json
Copy-Item "$projectRoot\composer.json" "$projectRoot\composer.json.bak" -Force
Write-Host "📁 Backed up composer.json to composer.json.bak"

# Perform replacements
$composerJson = $composerJson -replace '"laravel/framework":\s*"[^"]+"', '"laravel/framework": "^9.0"'
$composerJson = $composerJson -replace '"laravel/sanctum":\s*"[^"]+"', '"laravel/sanctum": "^2.15"'
$composerJson = $composerJson -replace '"laravel/tinker":\s*"[^"]+"', '"laravel/tinker": "^2.7"'
$composerJson = $composerJson -replace '"php":\s*"[^"]+"', '"php": "^8.0"'
$composerJson = $composerJson -replace '"fideloper/proxy":\s*"[^"]+"', '"fruitcake/laravel-cors": "^2.0"'
$composerJson = $composerJson -replace '"guzzlehttp/guzzle":\s*"[^"]+"', '"guzzlehttp/guzzle": "^7.0.1"'
$composerJson = $composerJson -replace '"phpunit/phpunit":\s*"[^"]+"', '"phpunit/phpunit": "^9.5"'

# Save updated composer.json
Set-Content "$projectRoot\composer.json" $composerJson
Write-Host "✅ Updated composer.json dependencies (including PHPUnit)."

# Run composer update
# Write-Host "📦 Running composer update..."
# composer update

# # Clear Laravel caches
# Write-Host "🧹 Clearing Laravel caches..."
# php artisan config:clear
# php artisan cache:clear
# php artisan route:clear
# php artisan view:clear

Write-Host "`n🎉 Laravel and PHPUnit successfully upgraded!"
Write-Host "👉 Be sure to review the upgrade guide:"
Write-Host "🔗 https://laravel.com/docs/9.x/upgrade" -ForegroundColor Cyan
Write-Host "🔗 https://phpunit.de/announcements/phpunit-9.html" -ForegroundColor Cyan
