$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$godotRoot = "C:\path\Godot"
$godotConsole = Join-Path $godotRoot "Godot_v4.7.2-stable_win64_console.exe"
$godotRuntime = Join-Path $godotRoot "Godot_v4.7.2-stable_win64.exe"
$outputDirectory = Join-Path $projectRoot "builds\windows"
$outputPack = Join-Path $outputDirectory "fracgame.pck"
$outputExecutable = Join-Path $outputDirectory "fracgame.exe"

if (-not (Test-Path -LiteralPath $godotConsole)) {
    throw "Godot console executable was not found: $godotConsole"
}
if (-not (Test-Path -LiteralPath $godotRuntime)) {
    throw "Godot runtime executable was not found: $godotRuntime"
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
& $godotConsole --headless --path $projectRoot --export-pack "Windows Desktop" $outputPack
if ($LASTEXITCODE -ne 0) {
    throw "Godot failed to create the project pack."
}

if (-not (Test-Path -LiteralPath $outputExecutable)) {
    Copy-Item -LiteralPath $godotRuntime -Destination $outputExecutable
}
Write-Output "Windows prototype created in: $outputDirectory"
