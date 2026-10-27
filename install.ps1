<#
.SYNOPSIS
  Dotfiles installer for native Windows (the PowerShell twin of install.sh).

.DESCRIPTION
  Same rules as install.sh: link, don't copy; include, don't replace; safe to
  re-run. What it does on Windows:

    - links ~/.editorconfig to the repo (copies it if symlinks aren't allowed)
    - adds one line to your PowerShell $PROFILE that dot-sources
      powershell/profile.ps1
    - adds git/gitconfig to ~/.gitconfig with [include]

  Skips tmux and the bash prompt. Inside WSL, run install.sh instead.

  Symlinks need Developer Mode (Settings > System > For developers) or an
  elevated shell; without either, files are copied and you should re-run this
  after each pull. Works in Windows PowerShell 5.1 and PowerShell 7+.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$DotfilesDir = $PSScriptRoot
$Tag = '# dotfiles-demo'

function Install-Link([string]$Src, [string]$Dst) {
  $item = Get-Item -LiteralPath $Dst -Force -ErrorAction SilentlyContinue
  if ($item -and $item.LinkType) {
    $item.Delete()
  } elseif ($item) {
    Move-Item -LiteralPath $Dst -Destination "$Dst.pre-dotfiles.bak" -Force
    Write-Host "  backed up $Dst -> $Dst.pre-dotfiles.bak"
  }
  try {
    New-Item -ItemType SymbolicLink -Path $Dst -Target $Src | Out-Null
    Write-Host "  linked $Dst"
  } catch {
    Copy-Item -LiteralPath $Src -Destination $Dst
    Write-Host "  copied $Dst (no symlink permission; re-run after pulling)"
  }
}

# Make $Line the only line tagged with $Tag in $File.
function Set-TaggedLine([string]$File, [string]$Line) {
  New-Item -ItemType Directory -Force -Path (Split-Path $File) | Out-Null
  $lines = @()
  if (Test-Path -LiteralPath $File) {
    $lines = @(Get-Content -LiteralPath $File | Where-Object { $_ -notlike "*$Tag*" })
  }
  $lines += "$Line  $Tag"
  Set-Content -LiteralPath $File -Value $lines
  Write-Host "  hooked $File"
}

Write-Host "dotfiles: installing from $DotfilesDir (windows)"

Write-Host 'Linking config files:'
Install-Link (Join-Path $DotfilesDir 'editorconfig') (Join-Path $HOME '.editorconfig')

Write-Host 'Hooking PowerShell profile:'
$profileScript = Join-Path $DotfilesDir 'powershell\profile.ps1'
Set-TaggedLine $PROFILE.CurrentUserAllHosts ". '$profileScript'"

Write-Host 'Including git config:'
if (Get-Command git -ErrorAction SilentlyContinue) {
  # Forward slashes: git reads the path the same either way, and they don't
  # need escaping.
  $gitconfig = (Join-Path $DotfilesDir 'git\gitconfig') -replace '\\', '/'
  git config --global --unset-all --fixed-value include.path $gitconfig 2>$null
  git config --global --add include.path $gitconfig
  Write-Host "  ~/.gitconfig includes $gitconfig"
} else {
  Write-Warning 'git not found; skipping (winget install Git.Git)'
}

Write-Host 'Done. Open a new PowerShell window.'
