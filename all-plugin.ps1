# Steamtools Educational Installer
# Modified for educational project use

## Configure this
$Host.UI.RawUI.WindowTitle = "Steamtools plugin installer | discord.gg/CCn9VGGc"
$name = "steamtools"
$link = "https://github.com/madoiscool/ltsteamplugin/releases/latest/download/ltsteamplugin.zip"
$milleniumTimer = 5

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

# Detect Steam path
$steam = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam").InstallPath
$upperName = $name.Substring(0, 1).ToUpper() + $name.Substring(1).ToLower()

#### Logging function ####
function Log {
    param ([string]$Type, [string]$Message, [boolean]$NoNewline = $false)

    switch ($Type.ToUpper()) {
        "OK" { $foreground = "Green" }
        "INFO" { $foreground = "Cyan" }
        "ERR" { $foreground = "Red" }
        "WARN" { $foreground = "Yellow" }
        "LOG" { $foreground = "Magenta" }
        default { $foreground = "White" }
    }

    $date = Get-Date -Format "HH:mm:ss"
    $prefix = if ($NoNewline) { "`r[$date] " } else { "[$date] " }

    Write-Host $prefix -ForegroundColor Cyan -NoNewline
    Write-Host "[$Type] $Message" -ForegroundColor $foreground -NoNewline:$NoNewline
}

Log "INFO" "Steamtools installer started"
Log "INFO" "Support: https://discord.gg/CCn9VGGc"
Write-Host

$ProgressPreference = 'SilentlyContinue'

# Close Steam if running
Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force

# Ensure plugins folder exists
if (!(Test-Path (Join-Path $steam "plugins"))) {
    New-Item -Path (Join-Path $steam "plugins") -ItemType Directory *> $null
}

$Path = Join-Path $steam "plugins\$name"
$subPath = Join-Path $env:TEMP "$name.zip"

Log "LOG" "Downloading plugin..."
Invoke-WebRequest -Uri $link -OutFile $subPath *> $null

if (!(Test-Path $subPath)) {
    Log "ERR" "Download failed"
    exit
}

Log "LOG" "Extracting plugin..."
Expand-Archive -Path $subPath -DestinationPath $Path -Force *> $null
Remove-Item $subPath -ErrorAction SilentlyContinue

Log "OK" "$upperName installed successfully"

# Enable plugin config
$configPath = Join-Path $steam "ext/config.json"

if (!(Test-Path $configPath)) {

    $config = @{
        plugins = @{
            enabledPlugins = @($name)
        }
    }

    New-Item -Path (Split-Path $configPath) -ItemType Directory -Force | Out-Null
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8

} else {

    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    if ($config.plugins.enabledPlugins -notcontains $name) {
        $config.plugins.enabledPlugins += $name
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
}

Log "OK" "Plugin enabled"

# Restart Steam
Start-Process (Join-Path $steam "steam.exe")

Log "INFO" "Steam restarted"
Log "INFO" "Installation complete"