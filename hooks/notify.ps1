param(
  [string]$Title = "Claude Code",
  [string]$Message = ""
)
# Windows balloon/toast notification used by Claude Code hooks (replaces macOS osascript).
# Invoked detached from notify.sh; sleeps briefly so the notification has time to render.
$ErrorActionPreference = "SilentlyContinue"
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
