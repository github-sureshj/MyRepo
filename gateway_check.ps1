# ================= PUBLIC CONFIG (Safe for GitHub) =================
$TARGET_PORT   = 18789                     
$TRIGGER_WORD  = "gateway start"  
# ===================================================================

$watcherDir  = "$env:APPDATA\ClawWatcher"
$secretsFile = "$watcherDir\secrets.json"
$offsetFile  = "$watcherDir\offset.txt"

if (Test-Path $secretsFile) {
    $secrets        = Get-Content $secretsFile | ConvertFrom-Json
    $BOT_TOKEN      = $secrets.BOT_TOKEN
    $USER_IDS       = $secrets.USER_IDS
    $LAUNCH_COMMAND = $secrets.LAUNCH_COMMAND

    # Load the last processed message ID to prevent missing commands in high-traffic queues
    $offset = if (Test-Path $offsetFile) { Get-Content $offsetFile | Out-String } else { 0 }
    $offset = [int64]$offset

    try {
        # Pull up to 10 unread messages at once
        $tgUrl   = "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$offset&limit=10"
        $updates = Invoke-RestMethod -Uri $tgUrl -Method Get -TimeoutSec 5

        if ($updates.ok -and $updates.result.Count -gt 0) {
            $shouldStart = $false
            $lastSenderId = $null

            foreach ($update in $updates.result) {
                # Increment offset to clear this message from Telegram's queue on next cycle
                $offset = $update.update_id + 1
                
                $msgText  = $update.message.text
                $senderId = [string]$update.message.from.id

                # Scan through all messages in the batch for an authorized trigger
                if ($USER_IDS -contains $senderId -and $msgText -ieq $TRIGGER_WORD) {
                    $shouldStart = $true
                    $lastSenderId = $senderId
                }
            }

            # Save the new offset marker locally
            Set-Content -Path $offsetFile -Value $offset -Force

            if ($shouldStart) {
                # Spin up the gateway
                Start-Process cmd.exe -ArgumentList "/c $LAUNCH_COMMAND" -WindowStyle Minimized
                
                # Send confirmation back to the user who triggered the launch
                $confirmUrl = "https://api.telegram.org/bot$BOT_TOKEN/sendMessage?chat_id=$lastSenderId&text=🚀 OpenClaw Gateway initialization command fired."
                Invoke-RestMethod -Uri $confirmUrl -Method Get -TimeoutSec 5
            }
        }
    } catch {
        # Fails silently during network drops
    }
}
