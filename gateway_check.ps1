# ================= PUBLIC CONFIG (Safe for GitHub) =================
$TARGET_PORT   = 18789                     
$TRIGGER_WORD  = "gateway start"  
# ===================================================================

$secretsFile = "$env:APPDATA\ClawWatcher\secrets.json"

if (Test-Path $secretsFile) {
    $secrets        = Get-Content $secretsFile | ConvertFrom-Json
    $BOT_TOKEN      = $secrets.BOT_TOKEN
    $USER_IDS       = $secrets.USER_IDS  # Reads the array of allowed IDs
    $LAUNCH_COMMAND = $secrets.LAUNCH_COMMAND

    try {
        $tgUrl   = "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=-1&limit=1"
        $updates = Invoke-RestMethod -Uri $tgUrl -Method Get -TimeoutSec 5

        if ($updates.ok -and $updates.result.Count -gt 0) {
            $latestMsg = $updates.result[0].message
            $msgText   = $latestMsg.text
            $senderId  = [string]$latestMsg.from.id  # Convert to string for solid matching

            # Dynamic Check: Is the sender ID in your local whitelist?
            if ($USER_IDS -contains $senderId -and $msgText -ieq $TRIGGER_WORD) {
                
                # Fire up the gateway globally out of sight
                Start-Process cmd.exe -ArgumentList "/c $LAUNCH_COMMAND" -WindowStyle Minimized
                
                # Sends confirmation specifically to the user who texted the bot
                $confirmUrl = "https://api.telegram.org/bot$BOT_TOKEN/sendMessage?chat_id=$senderId&text=🚀 OpenClaw Gateway initialization command fired."
                Invoke-RestMethod -Uri $confirmUrl -Method Get -TimeoutSec 5
            }
        }
    } catch {
        # Silent exception handling for dropouts
    }
}
