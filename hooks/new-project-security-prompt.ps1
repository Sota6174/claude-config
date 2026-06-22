# SessionStart hook (PowerShell, Windows): inject security-guidance plugin prompt
# for newly-encountered projects. Cross-platform counterpart: same-name .sh for mac/Linux.
#
# Source language note: this script intentionally contains only ASCII so that
# Windows PowerShell 5.1 (which reads BOM-less scripts as the legacy ANSI codepage,
# i.e. Shift_JIS on Japanese Windows) can parse it. Japanese context body is read
# from new-project-security-prompt.context.txt at runtime as UTF-8.
#
# Behavior:
#   - Only fires when source == "startup" (resume / clear / compact are ignored).
#   - If cwd or any ancestor (until $HOME) contains .claude/settings.json or
#     .claude/settings.local.json, treat as known project and exit.
#   - If cwd == $HOME, exit (running under global settings).
#   - Otherwise emit hookSpecificOutput.additionalContext as JSON to stdout.
#
# Reference: 05_security-guidance.md (see new-project-security-prompt.context.txt)

$ErrorActionPreference = 'SilentlyContinue'

# Non-Windows pwsh-core: defer to the .sh sibling.
if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
  exit 0
}

$inputRaw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($inputRaw)) { exit 0 }

try {
  $data = $inputRaw | ConvertFrom-Json -ErrorAction Stop
} catch {
  exit 0
}

$cwd = $data.cwd
$source = $data.source

if ($source -ne 'startup') { exit 0 }
if ([string]::IsNullOrWhiteSpace($cwd)) { exit 0 }

$homeDir = $HOME

if ($cwd.TrimEnd('\','/') -ieq $homeDir.TrimEnd('\','/')) {
  exit 0
}

$dir = $cwd
while ($dir -and (Test-Path -LiteralPath $dir)) {
  if ($dir.TrimEnd('\','/') -ieq $homeDir.TrimEnd('\','/')) { break }
  $settingsPath = Join-Path $dir '.claude\settings.json'
  $localSettingsPath = Join-Path $dir '.claude\settings.local.json'
  if ((Test-Path -LiteralPath $settingsPath) -or (Test-Path -LiteralPath $localSettingsPath)) {
    exit 0
  }
  $parent = Split-Path -Parent $dir
  if (-not $parent -or $parent -eq $dir) { break }
  $dir = $parent
}

# Load Japanese context body from sibling .txt as UTF-8 (works even on PS 5.1).
$contextPath = Join-Path $PSScriptRoot 'new-project-security-prompt.context.txt'
if (-not (Test-Path -LiteralPath $contextPath)) { exit 0 }
$context = [System.IO.File]::ReadAllText($contextPath, [System.Text.UTF8Encoding]::new($false))

$payload = [ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName     = 'SessionStart'
    additionalContext = $context
  }
}

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$json = $payload | ConvertTo-Json -Depth 5 -Compress
[Console]::Out.Write($json)
