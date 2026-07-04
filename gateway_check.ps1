# ================= PUBLIC CONFIG (Safe for GitHub) =================
# Modify these values on GitHub anytime to change script behavior instantly!
$TARGET_PORT   = 18789                     
$TRIGGER_WORD  = "gateway start"  
# ===================================================================

$secretsFile = "$env:APPDATA\ClawWatcher\secrets.json"

# Only execute if the local private credentials file exists on this PC
if (Test-Path $secretsFile) {
    $secrets        = Get-Content $secretsFile | ConvertFrom-Json
    $BOT_TOKEN      = $secrets.BOT_TOKEN
    $USER_ID        = $secrets.USER_ID
    $LAUNCH_COMMAND = $secrets.LAUNCH_COMMAND

    try {
        # Fetch the single latest message from your Telegram bot
        $tgUrl   = "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=-1&limit=1"
        $updates = Invoke-RestMethod -Uri $tgUrl -Method Get -TimeoutSec 5

        if ($updates.ok -and $updates.result.Count -gt 0) {
            $latestMsg = $updates.result[0].message
            $msgText   = $latestMsg.text
            $senderId  = $latestMsg.from.id

            # Verify the message sender is YOU and matches the trigger word
            if ($senderId -eq $USER_ID -and $msgText -ieq $TRIGGER_WORD) {
                
                # Spawns 'openclaw gateway' globally and keeps it minimized out of your way
                Start-Process cmd.exe -ArgumentList "/c $LAUNCH_COMMAND" -WindowStyle Minimized
                
                # Send confirmation ping back to your Telegram chat
                $confirmUrl = "https://api.telegram.org/bot$BOT_TOKEN/sendMessage?chat_id=$USER_ID&text=🚀 OpenClaw Gateway initialization command fired."
                Invoke-RestMethod -Uri $confirmUrl -Method Get -TimeoutSec 5
            }
        }
    } catch {
        # Fails silently during internet fluctuations to guarantee 0% CPU lockups
    }
}
