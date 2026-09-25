# keepawake.ps1 — guards against the Shadow (Blade) cloud PC's idle/session
# timeout firing mid-run. Windows' own sleep timer is already disabled
# (powercfg: Sleep after = 0 on AC/DC), so the observed crashes are believed
# to come from Shadow's own remote-session idle detection, which likely
# watches for real HID input rather than Windows power state. This holds
# SetThreadExecutionState AND nudges the cursor by one pixel every interval
# to cover both mechanisms. Started/stopped by orchestrate.sh around a block
# run; not meant to be left running unattended outside that window.

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class KeepAwakeNative {
    [DllImport("kernel32.dll")]
    public static extern uint SetThreadExecutionState(uint esFlags);
}
"@
Add-Type -AssemblyName System.Windows.Forms

# 0x80000000 overflows a signed int32 literal before the [uint32] cast is
# applied, so PowerShell 5.1 rejects `[uint32]0x80000000` directly — convert
# from the hex string instead.
$ES_CONTINUOUS       = [Convert]::ToUInt32("80000000", 16)
$ES_SYSTEM_REQUIRED  = [uint32]0x00000001
$ES_DISPLAY_REQUIRED = [uint32]0x00000002
$intervalSeconds = 60

Write-Output "$(Get-Date -Format o) keepawake started (pid $PID), interval ${intervalSeconds}s"

while ($true) {
    [KeepAwakeNative]::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED) | Out-Null
    try {
        $pos = [System.Windows.Forms.Cursor]::Position
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($pos.X + 1), $pos.Y)
        Start-Sleep -Milliseconds 200
        [System.Windows.Forms.Cursor]::Position = $pos
    } catch {
        # No interactive desktop session available (e.g. running headless/detached) — the
        # execution-state call above still runs; the cursor nudge is best-effort on top of it.
    }
    Start-Sleep -Seconds $intervalSeconds
}
