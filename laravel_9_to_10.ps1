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
    if (-not ($currentVersion.StartsWith("9."))) {
        Write-Host "⚠️ Detected Laravel version is $currentVersion (not 9.x)."
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

# Update composer.json dependencies
$composerJson = $composerJson -replace '"laravel/framework":\s*"[^"]+"', '"laravel/framework": "^10.0"'
$composerJson = $composerJson -replace '"laravel/sanctum":\s*"[^"]+"', '"laravel/sanctum": "^3.2"'
$composerJson = $composerJson -replace '"laravel/tinker":\s*"[^"]+"', '"laravel/tinker": "^2.8"'
$composerJson = $composerJson -replace '"php":\s*"[^"]+"', '"php": "^8.1"'
$composerJson = $composerJson -replace '"phpunit/phpunit":\s*"[^"]+"', '"phpunit/phpunit": "^10.0"'
$composerJson = $composerJson -replace '"guzzlehttp/guzzle":\s*"[^"]+"', '"guzzlehttp/guzzle": "^7.5"'

Set-Content "$projectRoot\composer.json" $composerJson
Write-Host "✅ Updated composer.json for Laravel 10, PHP ≥ 8.1, PHPUnit 10"

# Composer update
Write-Host "📦 Running composer update..."
# composer update

# # Laravel cache clear
# Write-Host "🧹 Clearing Laravel caches..."
# php artisan config:clear
# php artisan cache:clear
# php artisan route:clear
# php artisan view:clear

# Update phpunit.xml
$phpunitFile = "$projectRoot\phpunit.xml"
if (Test-Path $phpunitFile) {
    $xml = [xml](Get-Content $phpunitFile)
    $root = $xml.SelectSingleNode("/phpunit")

    # Required PHPUnit 10 settings
    $root.SetAttribute("executionOrder", "depends,defects")
    $root.SetAttribute("cacheResult", "true")
    $root.SetAttribute("colors", "true")
    $root.RemoveAttribute("backupGlobals")
    $root.RemoveAttribute("beStrictAboutCoversAnnotation")
    $root.RemoveAttribute("convertDeprecationsToExceptions")

    # Save
    $xml.Save($phpunitFile)
    Write-Host "🛠️ Updated phpunit.xml for PHPUnit 10."
} else {
    Write-Host "⚠️ phpunit.xml not found, skipping PHPUnit config update."
}

# Laravel Mix upgrade
$packageJsonFile = "$projectRoot\package.json"
if (Test-Path $packageJsonFile) {
    $packageJson = Get-Content $packageJsonFile -Raw
    $packageJson = $packageJson -replace '"laravel-mix":\s*"[^"]+"', '"laravel-mix": "^7.0.0"'
    $packageJson = $packageJson -replace '"webpack":\s*"[^"]+"', '"webpack": "^5.0.0"'
    Set-Content $packageJsonFile $packageJson
    Write-Host "🎛️ Updated Laravel Mix to v7 in package.json."

    # Optionally run npm install
    if (Test-Path "$projectRoot\package-lock.json") {
        Remove-Item "$projectRoot\package-lock.json"
    }
    Write-Host "📦 Running npm install..."
    npm install
} else {
    Write-Host "⚠️ package.json not found — skipping Laravel Mix upgrade."
}

Write-Host "`n✅ Upgrade to Laravel 10 completed!"
Write-Host "📘 Review breaking changes and test thoroughly:"
Write-Host "🔗 https://laravel.com/docs/10.x/upgrade" -ForegroundColor Cyan
Write-Host "🔗 https://phpunit.de/announcements/phpunit-10.html" -ForegroundColor Cyan
