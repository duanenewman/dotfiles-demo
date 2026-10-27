# PowerShell profile additions, dot-sourced from $PROFILE by install.ps1.
# The Windows-side cousin of shell/aliases.sh: same muscle memory, same names.

# gl is a built-in alias for Get-Location, and aliases beat functions.
Remove-Item Alias:gl -Force -ErrorAction SilentlyContinue

function gs { git status -sb @args }
function gl { git lg -20 @args }
function gd { git diff @args }
function ll { Get-ChildItem -Force @args }
function mkcd([string]$Path) { New-Item -ItemType Directory -Force -Path $Path | Out-Null; Set-Location $Path }
function groot { Set-Location (git rev-parse --show-toplevel) }

# Machine-specific or secret settings live outside the repo.
$local = Join-Path $HOME '.profile.local.ps1'
if (Test-Path $local) { . $local }
