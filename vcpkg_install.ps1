# vcpkg_install.ps1 - Install C++ packages using vcpkg

param(
    [string]$Package = ""
)

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

if (-not $Package) {
    Write-Host "Usage: .\vcpkg_install.ps1 -Package <package-name>" -ForegroundColor Yellow
    Write-Host "Example: .\vcpkg_install.ps1 -Package nlohmann-json" -ForegroundColor Cyan
    exit 1
}

Write-Host "Installing $Package using vcpkg..." -ForegroundColor Green

# Create cpp_modules directory if it doesn't exist
if (-not (Test-Path "cpp_modules")) {
    New-Item -ItemType Directory -Path "cpp_modules" | Out-Null
    Write-Host "Created cpp_modules directory" -ForegroundColor Cyan
}

# Install package with vcpkg
Write-Host "Running: vcpkg install ${Package}:x64-windows" -ForegroundColor Cyan
$result = & $VCPKG_EXE install "${Package}:x64-windows" --no-print-usage
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "Error: vcpkg installation failed" -ForegroundColor Red
    exit $exitCode
}

Write-Host "Package installed successfully with vcpkg" -ForegroundColor Green

# Get vcpkg installed directory
$vcpkgInstalled = Join-Path $VCPKG_ROOT "installed\x64-windows"
$includeDir = Join-Path $vcpkgInstalled "include"
$libDir = Join-Path $vcpkgInstalled "lib"

# Sanitize package name for directory
$sanitizedName = $Package -replace '/', '_' -replace '-', '_'
$moduleDir = "cpp_modules/$sanitizedName"

# Create module directory structure
if (-not (Test-Path $moduleDir)) {
    New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$moduleDir/include" -Force | Out-Null
    New-Item -ItemType Directory -Path "$moduleDir/lib" -Force | Out-Null
}

# Copy headers from vcpkg
Write-Host "Copying headers to $moduleDir/include..." -ForegroundColor Cyan

# Determine which headers to copy based on package
$packageHeaders = @{
    "nlohmann-json" = @("nlohmann")
    "fmt" = @("fmt")
    "boost" = @("boost")
    "catch2" = @("catch2")
    "spdlog" = @("spdlog")
}

$headersToCopy = $packageHeaders[$Package]

if ($headersToCopy) {
    foreach ($header in $headersToCopy) {
        $srcPath = Join-Path $includeDir $header
        if (Test-Path $srcPath) {
            Copy-Item -Path $srcPath -Destination "$moduleDir/include/" -Recurse -Force
            Write-Host "  Copied $header" -ForegroundColor Green
        }
    }
} else {
    # Try to copy all headers if package not in registry
    if (Test-Path $includeDir) {
        Copy-Item -Path "$includeDir\*" -Destination "$moduleDir/include/" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Copied all available headers" -ForegroundColor Green
    }
}

# Copy libraries if they exist
if (Test-Path $libDir) {
    Copy-Item -Path "$libDir\*.lib" -Destination "$moduleDir/lib/" -Force -ErrorAction SilentlyContinue
    Write-Host "Copied libraries to $moduleDir/lib" -ForegroundColor Green
}

# Get version from vcpkg
Write-Host "Getting package version..." -ForegroundColor Cyan
$versionOutput = & $VCPKG_EXE list $Package
$version = "latest"
if ($versionOutput -match "${Package}:x64-windows\s+([\d\.]+)") {
    $version = $matches[1]
}

# Update cpp_package.json
$packageJsonPath = "cpp_package.json"
$packageConfig = @{
    name = "my-cpp-project"
    version = "1.0.0"
    dependencies = @{}
    compiler = @{
        standard = "c++17"
        optimization = "-O2"
    }
}

# Read existing config if it exists
if (Test-Path $packageJsonPath) {
    try {
        $existingConfig = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
        $packageConfig = @{
            name = $existingConfig.name
            version = $existingConfig.version
            dependencies = @{}
            compiler = @{
                standard = $existingConfig.compiler.standard
                optimization = $existingConfig.compiler.optimization
            }
        }
        # Copy existing dependencies
        $existingConfig.dependencies.PSObject.Properties | ForEach-Object {
            $packageConfig.dependencies[$_.Name] = @{
                version = $_.Value.version
                include = $_.Value.include
                lib = $_.Value.lib
            }
        }
    } catch {
        Write-Host "Warning: Could not parse existing cpp_package.json, will create new one" -ForegroundColor Yellow
    }
}

# Add or update the new package
$packageConfig.dependencies[$Package] = @{
    version = $version
    include = "$moduleDir/include"
}

# Add lib path if libraries exist
if (Test-Path "$moduleDir/lib/*.lib") {
    $packageConfig.dependencies[$Package].lib = "$moduleDir/lib"
}

# Write updated config
$jsonOutput = $packageConfig | ConvertTo-Json -Depth 10
$jsonOutput | Set-Content $packageJsonPath -Encoding UTF8

Write-Host "`nSuccessfully installed $Package!" -ForegroundColor Green
Write-Host "  Version: $version" -ForegroundColor Cyan
Write-Host "  Location: $moduleDir" -ForegroundColor Cyan
Write-Host "  Updated: cpp_package.json" -ForegroundColor Cyan
Write-Host "`nYou can now use it by running:" -ForegroundColor Yellow
Write-Host "  .\gwrap.exe -std=c++17 your_code.cpp -o output.exe" -ForegroundColor White
