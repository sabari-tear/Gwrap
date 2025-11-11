# gwrap_config.ps1 - Configuration manager for gwrap

param(
    [string]$Action = "",
    [string]$Tool = "",
    [string]$Path = ""
)

$configFile = "gwrap_config.json"

# Function to find executable in PATH
function Find-InPath {
    param([string]$ExeName)
    
    $found = Get-Command $ExeName -ErrorAction SilentlyContinue
    if ($found) {
        return $found.Source
    }
    return $null
}

# Function to check default locations
function Find-Tool {
    param([string]$Tool)
    
    if ($Tool -eq "vcpkg") {
        # Check default locations for vcpkg
        $defaultLocations = @(
            "C:\vcpkg\vcpkg.exe",
            "$env:VCPKG_ROOT\vcpkg.exe",
            "C:\tools\vcpkg\vcpkg.exe",
            "$env:USERPROFILE\vcpkg\vcpkg.exe"
        )
        
        foreach ($loc in $defaultLocations) {
            if (Test-Path $loc) {
                return $loc
            }
        }
        
        # Check in PATH
        return Find-InPath "vcpkg.exe"
    }
    elseif ($Tool -eq "gpp") {
        # Check for g++ in PATH
        $gppPath = Find-InPath "g++.exe"
        if ($gppPath) {
            return $gppPath
        }
        
        # Check common MinGW locations
        $defaultLocations = @(
            "C:\mingw64\bin\g++.exe",
            "C:\MinGW\bin\g++.exe",
            "C:\msys64\mingw64\bin\g++.exe",
            "C:\Program Files\mingw-w64\bin\g++.exe"
        )
        
        foreach ($loc in $defaultLocations) {
            if (Test-Path $loc) {
                return $loc
            }
        }
    }
    
    return $null
}

# Function to load config
function Get-Config {
    if (Test-Path $configFile) {
        try {
            return Get-Content $configFile -Raw | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

# Function to save config
function Save-Config {
    param($Config)
    
    $jsonOutput = $Config | ConvertTo-Json -Depth 10
    $jsonOutput | Set-Content $configFile -Encoding UTF8
}

# Function to initialize config
function Initialize-Config {
    Write-Host "Initializing gwrap configuration..." -ForegroundColor Cyan
    Write-Host ""
    
    $config = @{
        vcpkg_path = ""
        gpp_path = ""
    }
    
    # Find vcpkg
    Write-Host "Searching for vcpkg..." -ForegroundColor Yellow
    $vcpkgPath = Find-Tool "vcpkg"
    
    if ($vcpkgPath) {
        Write-Host "  Found: $vcpkgPath" -ForegroundColor Green
        $config.vcpkg_path = $vcpkgPath
    } else {
        Write-Host "  Not found in default locations" -ForegroundColor Red
        Write-Host ""
        $userPath = Read-Host "Enter vcpkg.exe path (or press Enter to skip)"
        if ($userPath -and (Test-Path $userPath)) {
            $config.vcpkg_path = $userPath
            Write-Host "  Set to: $userPath" -ForegroundColor Green
        } else {
            Write-Host "  vcpkg path not set - install command will not work" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    # Find g++
    Write-Host "Searching for g++..." -ForegroundColor Yellow
    $gppPath = Find-Tool "gpp"
    
    if ($gppPath) {
        Write-Host "  Found: $gppPath" -ForegroundColor Green
        $config.gpp_path = $gppPath
    } else {
        Write-Host "  Not found in default locations" -ForegroundColor Red
        Write-Host ""
        $userPath = Read-Host "Enter g++.exe path (or press Enter to skip)"
        if ($userPath -and (Test-Path $userPath)) {
            $config.gpp_path = $userPath
            Write-Host "  Set to: $userPath" -ForegroundColor Green
        } else {
            Write-Host "  g++ path not set - compilation will not work" -ForegroundColor Yellow
        }
    }
    
    Save-Config $config
    
    Write-Host ""
    Write-Host "Configuration saved to $configFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can update paths anytime with:" -ForegroundColor Cyan
    Write-Host "  .\gwrap.exe config set vcpkg <path>" -ForegroundColor White
    Write-Host "  .\gwrap.exe config set gpp <path>" -ForegroundColor White
}

# Function to set a config value
function Set-ConfigValue {
    param([string]$Tool, [string]$Path)
    
    $config = Get-Config
    if (-not $config) {
        $config = @{
            vcpkg_path = ""
            gpp_path = ""
        }
    }
    
    if (-not (Test-Path $Path)) {
        Write-Host "Error: Path does not exist: $Path" -ForegroundColor Red
        exit 1
    }
    
    if ($Tool -eq "vcpkg") {
        $config.vcpkg_path = $Path
        Write-Host "vcpkg path set to: $Path" -ForegroundColor Green
    }
    elseif ($Tool -eq "gpp") {
        $config.gpp_path = $Path
        Write-Host "g++ path set to: $Path" -ForegroundColor Green
    }
    else {
        Write-Host "Error: Unknown tool '$Tool'. Use 'vcpkg' or 'gpp'" -ForegroundColor Red
        exit 1
    }
    
    Save-Config $config
}

# Function to show current config
function Show-Config {
    $config = Get-Config
    
    if (-not $config) {
        Write-Host "No configuration found. Run:" -ForegroundColor Yellow
        Write-Host "  .\gwrap.exe config init" -ForegroundColor White
        exit 0
    }
    
    Write-Host "Current configuration:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  vcpkg: " -NoNewline -ForegroundColor Yellow
    if ($config.vcpkg_path) {
        Write-Host $config.vcpkg_path -ForegroundColor White
    } else {
        Write-Host "(not set)" -ForegroundColor Red
    }
    
    Write-Host "  g++:   " -NoNewline -ForegroundColor Yellow
    if ($config.gpp_path) {
        Write-Host $config.gpp_path -ForegroundColor White
    } else {
        Write-Host "(not set)" -ForegroundColor Red
    }
}

# Main logic
if ($Action -eq "init") {
    Initialize-Config
}
elseif ($Action -eq "set") {
    if (-not $Tool -or -not $Path) {
        Write-Host "Usage: .\gwrap.exe config set <tool> <path>" -ForegroundColor Yellow
        Write-Host "Example: .\gwrap.exe config set vcpkg C:\vcpkg\vcpkg.exe" -ForegroundColor Cyan
        exit 1
    }
    Set-ConfigValue -Tool $Tool -Path $Path
}
elseif ($Action -eq "show" -or $Action -eq "") {
    Show-Config
}
else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\gwrap.exe config init              # Initialize configuration" -ForegroundColor White
    Write-Host "  .\gwrap.exe config show              # Show current configuration" -ForegroundColor White
    Write-Host "  .\gwrap.exe config set vcpkg <path>  # Set vcpkg path" -ForegroundColor White
    Write-Host "  .\gwrap.exe config set gpp <path>    # Set g++ path" -ForegroundColor White
}
