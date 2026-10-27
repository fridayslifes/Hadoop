# Forwarder to setup.ps1 for universal installation
$ScriptPath = Join-Path $PSScriptRoot "setup.ps1"
if (Test-Path $ScriptPath) {
    & $ScriptPath
} else {
    irm https://raw.githubusercontent.com/fridayslifes/Hadoop/main/setup.ps1 | iex
}
