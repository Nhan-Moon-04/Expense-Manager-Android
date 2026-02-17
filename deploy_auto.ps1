# =====================================================
# Script tự động build và deploy APK lên Armbian Server
# =====================================================
# Usage:
#   .\deploy_auto.ps1                                    # Auto-increment patch (1.0.0 -> 1.0.1)
#   .\deploy_auto.ps1 -Version "1.2.0"                   # Specify version manually
#   .\deploy_auto.ps1 -IncrementType "minor"             # Increment minor (1.0.5 -> 1.1.0)
#   .\deploy_auto.ps1 -ReleaseNotes "Bug fixes"          # Add release notes

param(
    [Parameter(Mandatory=$false)]
    [string]$Version = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("patch", "minor", "major")]
    [string]$IncrementType = "patch",
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseNotes = "",
    
    [Parameter(Mandatory=$false)]
    [bool]$ForceUpdate = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$ArmbianHost = "nthiennhan.ddns.net",
    
    [Parameter(Mandatory=$false)]
    [string]$ArmbianUser = "root",
    
    [Parameter(Mandatory=$false)]
    [string]$ArmbianPassword = "nguyennhan2004",
    
    [Parameter(Mandatory=$false)]
    [string]$ArmbianPath = "/var/www/html/app",
    
    [Parameter(Mandatory=$false)]
    [int]$ArmbianPort = 90
)

$ErrorActionPreference = "Stop"

# =====================================================
# FUNCTIONS
# =====================================================

function Get-CurrentVersion {
    $pubspecPath = "pubspec.yaml"
    if (-not (Test-Path $pubspecPath)) {
        throw "Khong tim thay file pubspec.yaml"
    }
    
    $content = Get-Content $pubspecPath -Raw
    if ($content -match 'version:\s*(\d+\.\d+\.\d+)\+\d+') {
        return $matches[1]
    } else {
        throw "Khong doc duoc version tu pubspec.yaml"
    }
}

function Get-CurrentBuildNumber {
    $pubspecPath = "pubspec.yaml"
    $content = Get-Content $pubspecPath -Raw
    if ($content -match 'version:\s*\d+\.\d+\.\d+\+(\d+)') {
        return [int]$matches[1]
    }
    return 0
}

function Increment-Version {
    param(
        [string]$CurrentVersion,
        [string]$Type
    )
    
    $parts = $CurrentVersion -split '\.'
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]
    
    switch ($Type) {
        "major" { 
            $major++
            $minor = 0
            $patch = 0
        }
        "minor" { 
            $minor++
            $patch = 0
        }
        "patch" { 
            $patch++
        }
    }
    
    return "$major.$minor.$patch"
}

function Update-PubspecVersion {
    param(
        [string]$NewVersion
    )
    
    $pubspecPath = "pubspec.yaml"
    $content = Get-Content $pubspecPath -Raw
    
    # Get current build number and increment
    $buildNumber = (Get-CurrentBuildNumber) + 1
    
    # Update version
    $content = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $NewVersion+$buildNumber"
    Set-Content $pubspecPath -Value $content -NoNewline
    
    return $buildNumber
}

function Test-PlinkAvailable {
    try {
        $null = Get-Command plink -ErrorAction Stop
        $null = Get-Command pscp -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Cache-HostKey {
    param(
        [string]$RemoteHost,
        [string]$User,
        [string]$Password
    )
    
    if (Test-PlinkAvailable) {
        # Use plink to cache the host key
        Write-Host "  Caching host key for $RemoteHost..." -ForegroundColor Gray
        $plinkArgs = @(
            "-pw", $Password,
            "${User}@${RemoteHost}",
            "echo 'Connected'"
        )
        # Don't use -batch for first connection to allow key acceptance
        $env:PLINK_PROTOCOL = "ssh"
        echo y | & plink @plinkArgs 2>&1 | Out-Null
    }
}

function Upload-FileWithPassword {
    param(
        [string]$LocalPath,
        [string]$RemotePath,
        [string]$RemoteHost,
        [string]$User,
        [string]$Password
    )
    
    if (Test-PlinkAvailable) {
        # Use PuTTY pscp (supports -pw for password)
        Write-Host "  Using pscp..." -ForegroundColor Gray
        $pscpArgs = @(
            "-pw", $Password,
            "-batch",
            $LocalPath,
            "${User}@${RemoteHost}:${RemotePath}"
        )
        & pscp @pscpArgs
    } else {
        # Fallback to scp (will prompt for password)
        Write-Host "  Using scp (you may need to enter password)..." -ForegroundColor Yellow
        Write-Host "  Password: $Password" -ForegroundColor Cyan
        & scp $LocalPath "${User}@${RemoteHost}:${RemotePath}"
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Upload failed"
    }
}

function Run-RemoteCommandWithPassword {
    param(
        [string]$Command,
        [string]$RemoteHost,
        [string]$User,
        [string]$Password
    )
    
    if (Test-PlinkAvailable) {
        # Use PuTTY plink (supports -pw for password)
        Write-Host "  Using plink..." -ForegroundColor Gray
        $plinkArgs = @(
            "-pw", $Password,
            "-batch",
            "${User}@${RemoteHost}",
            $Command
        )
        & plink @plinkArgs
    } else {
        # Fallback to ssh (will prompt for password)
        Write-Host "  Using ssh (you may need to enter password)..." -ForegroundColor Yellow
        Write-Host "  Password: $Password" -ForegroundColor Cyan
        & ssh "${User}@${RemoteHost}" $Command
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Remote command failed"
    }
}

# =====================================================
# MAIN SCRIPT
# =====================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Expense Manager - Auto Deploy       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for PuTTY tools
if (-not (Test-PlinkAvailable)) {
    Write-Host "WARNING: PuTTY tools not found (plink/pscp)" -ForegroundColor Yellow
    Write-Host "   You can download from: https://www.putty.org/" -ForegroundColor Yellow
    Write-Host "   Or install via: winget install -e --id PuTTY.PuTTY" -ForegroundColor Yellow
    Write-Host "   Will use ssh/scp instead (manual password entry required)" -ForegroundColor Yellow
    Write-Host ""
}

# Get or calculate version
$currentVersion = Get-CurrentVersion
$currentBuild = Get-CurrentBuildNumber

if ([string]::IsNullOrEmpty($Version)) {
    $Version = Increment-Version -CurrentVersion $currentVersion -Type $IncrementType
    Write-Host "Current version: $currentVersion+$currentBuild" -ForegroundColor Yellow
    Write-Host "New version:     $Version (auto-increment $IncrementType)" -ForegroundColor Green
} else {
    Write-Host "Current version: $currentVersion+$currentBuild" -ForegroundColor Yellow
    Write-Host "New version:     $Version (manual)" -ForegroundColor Green
}

# Update pubspec.yaml
$buildNumber = Update-PubspecVersion -NewVersion $Version
Write-Host "Updated pubspec.yaml to $Version+$buildNumber" -ForegroundColor Green
Write-Host ""

# Set filenames
$APK_NAME = "expense_manager_v${Version}.apk"
$VERSION_JSON = "version.json"
$BUILD_APK_PATH = "build\app\outputs\flutter-apk\app-release.apk"

Write-Host "Target: $ArmbianUser@$ArmbianHost" -ForegroundColor Cyan
Write-Host "Path:   $ArmbianPath" -ForegroundColor Cyan
Write-Host ""

# =====================================================
# STEP 1: Build APK
# =====================================================

Write-Host "[1/6] Building APK with Flutter..." -ForegroundColor Green
Write-Host ""


flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

if (-Not (Test-Path $BUILD_APK_PATH)) {
    Write-Host ""
    Write-Host "APK not found at: $BUILD_APK_PATH" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "APK built successfully" -ForegroundColor Green
Write-Host ""

# =====================================================
# STEP 2: Read minimum version from pubspec.yaml
# =====================================================

Write-Host "[2/6] Reading minimum version requirement..." -ForegroundColor Green

$pubspecContent = Get-Content "pubspec.yaml" -Raw
$minVersion = "1.0.0"  # Default

# Try to extract min version from comments or custom field
if ($pubspecContent -match 'min_version:\s*"?(\d+\.\d+\.\d+)"?') {
    $minVersion = $matches[1]
    Write-Host "Found min_version: $minVersion" -ForegroundColor Green
} else {
    Write-Host "No min_version found, using default: $minVersion" -ForegroundColor Yellow
}

Write-Host ""

# =====================================================
# STEP 3: Generate version.json
# =====================================================

Write-Host "[3/6] Creating version.json..." -ForegroundColor Green

$downloadUrl = "http://${ArmbianHost}:${ArmbianPort}/app/$APK_NAME"

# Auto-generate release notes if not provided
if ([string]::IsNullOrEmpty($ReleaseNotes)) {
    $versionParts = $Version -split '\.'    
    $major = [int]$versionParts[0]
    $minor = [int]$versionParts[1]
    $patch = [int]$versionParts[2]
    
    if ($patch -gt 0) {
        $ReleaseNotes = "- Sua loi nho`n- Cai thien hieu suat"
    } elseif ($minor -gt 0) {
        $ReleaseNotes = "- Tinh nang moi`n- Cai tien giao dien`n- Sua loi"
    }  else {
        $ReleaseNotes = "- Phien ban chinh thuc moi`n- Nhieu tinh nang moi`n- Cai thien toan dien"
    }
}

$versionData = @{
    latestVersion = $Version
    minVersion = $minVersion
    downloadUrl = $downloadUrl
    releaseNotes = $ReleaseNotes
    forceUpdate = $ForceUpdate
    releaseDate = (Get-Date).ToString("yyyy-MM-dd")
}

$versionJson = $versionData | ConvertTo-Json -Depth 10
Set-Content -Path $VERSION_JSON -Value $versionJson

Write-Host "Generated version.json:" -ForegroundColor Green
Write-Host $versionJson -ForegroundColor Gray
Write-Host ""

# =====================================================
# STEP 4: Upload APK to Armbian
# =====================================================

Write-Host "[4/6] Uploading APK to Armbian server..." -ForegroundColor Green

# Cache host key on first connection
if (Test-PlinkAvailable) {
    Cache-HostKey -RemoteHost $ArmbianHost -User $ArmbianUser -Password $ArmbianPassword
}

try {
    Upload-FileWithPassword -LocalPath $BUILD_APK_PATH -RemotePath "$ArmbianPath/$APK_NAME" -RemoteHost $ArmbianHost -User $ArmbianUser -Password $ArmbianPassword
    Write-Host "APK uploaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to upload APK: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# =====================================================
# STEP 5: Upload version.json to Armbian
# =====================================================

Write-Host "[5/6] Uploading version.json to Armbian server..." -ForegroundColor Green

try {
    Upload-FileWithPassword -LocalPath $VERSION_JSON -RemotePath "$ArmbianPath/$VERSION_JSON" -RemoteHost $ArmbianHost -User $ArmbianUser -Password $ArmbianPassword
    Write-Host "version.json uploaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to upload version.json: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# =====================================================
# STEP 6: Set permissions on server
# =====================================================

Write-Host "[6/6] Setting file permissions on server..." -ForegroundColor Green

# Use format string to avoid parsing issues with &&
$permissionCommands = 'cd {0} && chmod 644 {1} {2} && chown www-data:www-data {1} {2}' -f $ArmbianPath, $APK_NAME, $VERSION_JSON

try {
    Run-RemoteCommandWithPassword -Command $permissionCommands -RemoteHost $ArmbianHost -User $ArmbianUser -Password $ArmbianPassword
    Write-Host "Permissions set successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to set permissions (may need manual fix): $_" -ForegroundColor Yellow
}

Write-Host ""

# =====================================================
# DONE
# =====================================================

Write-Host "========================================" -ForegroundColor Green
Write-Host "   DEPLOYMENT SUCCESSFUL!              " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "APK URL:       $downloadUrl" -ForegroundColor Cyan
Write-Host "Version URL:   http://${ArmbianHost}:${ArmbianPort}/app/$VERSION_JSON" -ForegroundColor Cyan
Write-Host "Version:       $Version+$buildNumber" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test URLs in browser:" -ForegroundColor Yellow
Write-Host "   http://${ArmbianHost}:${ArmbianPort}/app/$VERSION_JSON" -ForegroundColor Gray
Write-Host "   http://${ArmbianHost}:${ArmbianPort}/app/$APK_NAME" -ForegroundColor Gray
Write-Host ""
Write-Host "Tip: Install PuTTY tools for automated password handling:" -ForegroundColor Yellow
Write-Host "   winget install -e --id PuTTY.PuTTY" -ForegroundColor Gray
Write-Host ""
