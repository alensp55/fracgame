param(
    [Parameter(Mandatory = $true)]
    [string]$GodotConsole,

    [Parameter(Mandatory = $true)]
    [string]$GodotRuntime
)

$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$outputDirectory = Join-Path $projectRoot "builds\windows"
$outputPack = Join-Path $outputDirectory "fracgame.pck"
$outputExecutable = Join-Path $outputDirectory "fracgame.exe"

if (-not (Test-Path -LiteralPath $GodotConsole)) {
    throw "Godot console executable was not found: $GodotConsole"
}
if (-not (Test-Path -LiteralPath $GodotRuntime)) {
    throw "Godot runtime executable was not found: $GodotRuntime"
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
& $GodotConsole --headless --path $projectRoot --export-pack "Windows Desktop" $outputPack
if ($LASTEXITCODE -ne 0) {
    throw "Godot failed to create the project pack."
}

if (-not (Test-Path -LiteralPath $outputExecutable)) {
    Copy-Item -LiteralPath $GodotRuntime -Destination $outputExecutable
}
Write-Output "Windows prototype created in: $outputDirectory"
