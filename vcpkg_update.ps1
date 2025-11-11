# vcpkg_update.ps1 - Update all C++ packages to latest versions

# Load configuration
$configFile = "gwrap_config.json"
if (-not (Test-Path $configFile)) {
    Write-Host "Error: Configuration not found. Please run:" -ForegroundColor Red
    Write-Host "  .\gwrap.exe config init" -ForegroundColor Yellow
    exit 1
}

try {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json
} catch {
    Write-Host "Error: Failed to read configuration" -ForegroundColor Red
    exit 1
}

$VCPKG_EXE = $config.vcpkg_path

# Check if vcpkg is configured
if (-not $VCPKG_EXE -or -not (Test-Path $VCPKG_EXE)) {
    Write-Host "Error: vcpkg not configured or not found" -ForegroundColor Red
    Write-Host "Please run: .\gwrap.exe config init" -ForegroundColor Yellow
    Write-Host "Or set manually: .\gwrap.exe config set vcpkg <path>" -ForegroundColor Cyan
    exit 1
}

# Get vcpkg root from executable path
$VCPKG_ROOT = Split-Path -Parent $VCPKG_EXE

# Check if cpp_package.json exists
if (-not (Test-Path "cpp_package.json")) {
    Write-Host "Error: cpp_package.json not found" -ForegroundColor Red
    Write-Host "No packages to update" -ForegroundColor Yellow
    exit 1
}

Write-Host "Checking for package updates..." -ForegroundColor Cyan
Write-Host ""

# Read cpp_package.json
try {
    $config = Get-Content "cpp_package.json" -Raw | ConvertFrom-Json
} catch {
    Write-Host "Error: Failed to parse cpp_package.json" -ForegroundColor Red
    exit 1
}

if (-not $config.dependencies) {
    Write-Host "No dependencies found in cpp_package.json" -ForegroundColor Yellow
    exit 0
}

$packagesToUpdate = @()

# Check each package for updates
foreach ($dep in $config.dependencies.PSObject.Properties) {
    $packageName = $dep.Name
    $currentVersion = $dep.Value.version
    
    Write-Host "Checking $packageName (current: $currentVersion)..." -ForegroundColor Cyan
    
    # Get latest version from vcpkg
    $vcpkgOutput = & $VCPKG_EXE search $packageName 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $vcpkgOutput) {
        # Parse version from vcpkg search output
        $latestVersion = "unknown"
        
        foreach ($line in $vcpkgOutput) {
            if ($line -match "^$packageName\s+([\d\.]+)") {
                $latestVersion = $matches[1]
                break
            }
        }
        
        if ($latestVersion -ne "unknown" -and $latestVersion -ne $currentVersion) {
            Write-Host "  Update available: $currentVersion -> $latestVersion" -ForegroundColor Yellow
            $packagesToUpdate += @{
                name = $packageName
                currentVersion = $currentVersion
                latestVersion = $latestVersion
            }
        } else {
            Write-Host "  Already up to date" -ForegroundColor Green
        }
    } else {
        Write-Host "  Could not check for updates" -ForegroundColor Gray
    }
}

if ($packagesToUpdate.Count -eq 0) {
    Write-Host ""
    Write-Host "All packages are up to date!" -ForegroundColor Green
    exit 0
}

# Show summary
Write-Host ""
Write-Host "Packages to update:" -ForegroundColor Yellow
foreach ($pkg in $packagesToUpdate) {
    Write-Host "  - $($pkg.name): $($pkg.currentVersion) -> $($pkg.latestVersion)"
}

Write-Host ""
$confirm = Read-Host "Update all packages? (y/n)"

if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Update cancelled" -ForegroundColor Yellow
    exit 0
}

# Update packages
Write-Host ""
Write-Host "Updating packages..." -ForegroundColor Green

foreach ($pkg in $packagesToUpdate) {
    Write-Host ""
    Write-Host "Updating $($pkg.name)..." -ForegroundColor Cyan
    
    # Upgrade package with vcpkg
    & $VCPKG_EXE upgrade "$($pkg.name):x64-windows" --no-print-usage
    
    if ($LASTEXITCODE -eq 0) {
        # Reinstall to get latest version
        & $VCPKG_EXE install "$($pkg.name):x64-windows" --no-print-usage
        
        # Get vcpkg installed directory
        $vcpkgInstalled = Join-Path $VCPKG_ROOT "installed\x64-windows"
        $includeDir = Join-Path $vcpkgInstalled "include"
        $libDir = Join-Path $vcpkgInstalled "lib"
        
        # Sanitize package name for directory
        $sanitizedName = $pkg.name -replace '/', '_' -replace '-', '_'
        $moduleDir = "cpp_modules/$sanitizedName"
        
        # Clean old version
        if (Test-Path "$moduleDir/include") {
            Remove-Item "$moduleDir/include" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$moduleDir/lib") {
            Remove-Item "$moduleDir/lib" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Create directories
        New-Item -ItemType Directory -Path "$moduleDir/include" -Force | Out-Null
        New-Item -ItemType Directory -Path "$moduleDir/lib" -Force | Out-Null
        
        # Copy headers
        $packageHeaders = @{
            "nlohmann-json" = @("nlohmann")
            "fmt" = @("fmt")
            "boost" = @("boost")
            "catch2" = @("catch2")
            "spdlog" = @("spdlog")
        }
        
        $headersToCopy = $packageHeaders[$pkg.name]
        
        if ($headersToCopy) {
            foreach ($header in $headersToCopy) {
                $srcPath = Join-Path $includeDir $header
                if (Test-Path $srcPath) {
                    Copy-Item -Path $srcPath -Destination "$moduleDir/include/" -Recurse -Force
                }
            }
        } else {
            if (Test-Path $includeDir) {
                Copy-Item -Path "$includeDir\*" -Destination "$moduleDir/include/" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Copy libraries
        if (Test-Path $libDir) {
            Copy-Item -Path "$libDir\*.lib" -Destination "$moduleDir/lib/" -Force -ErrorAction SilentlyContinue
        }
        
        # Update version in config
        $config.dependencies.$($pkg.name).version = $pkg.latestVersion
        
        Write-Host "  Updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "  Update failed" -ForegroundColor Red
    }
}

# Write updated config
$jsonOutput = $config | ConvertTo-Json -Depth 10
$jsonOutput | Set-Content "cpp_package.json" -Encoding UTF8

Write-Host ""
Write-Host "All packages updated!" -ForegroundColor Green
Write-Host ""
Write-Host "Rebuild gwrap to use the updated packages:" -ForegroundColor Yellow
Write-Host "  g++ -std=c++17 -O2 gwrap.cpp -o gwrap.exe" -ForegroundColor White
