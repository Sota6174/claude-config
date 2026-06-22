param(
  [string]$Title = "Claude Code",
  [string]$Message = ""
)
# Windows balloon/toast notification used by Claude Code hooks (replaces macOS osascript).
# ASCII-only source: Windows PowerShell 5.1 reads BOM-less scripts as the legacy ANSI
# codepage (Shift_JIS on Japanese Windows), which corrupts any non-ASCII tokens here.
# Keep Title/Message payloads as runtime arguments (UTF-16 string params handle Japanese fine).
$ErrorActionPreference = "SilentlyContinue"

# Skip on non-Windows pwsh-core (mac/Linux use notify.sh).
if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
  exit 0
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$n = New-Object System.Windows.Forms.NotifyIcon
$n.Icon = [System.Drawing.SystemIcons]::Information
$n.BalloonTipTitle = $Title
$n.BalloonTipText = $Message
$n.Visible = $true
$n.ShowBalloonTip(4000)
Start-Sleep -Seconds 4
$n.Dispose()
